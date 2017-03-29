{ StubSpec } = require "../model/stub"
_ = require "lodash"


# Currently, a new stub printer needs to be created for every stub that
# gets printed, due to the printer's internal state.
module.exports.StubPrinter = class StubPrinter

  TAB_LENGTH: 4

  constructor: ->
    @string = ""
    @anonymousClassCounter = 0
    @indentLevel = 0
    @previousLineEmpty = false
    @static = false

  _addLine: (string) ->

    # Print spaces for all tabs at this indent level
    @string += (Array (@indentLevel * @TAB_LENGTH + 1)).join " "

    # Print the string
    @string += (string + "\n")

    # Whenever we print a line, indicate that we are not longer on an empty line
    @previousLineEmpty = (string is "")

  _addPaddingLine: ->
    if not @previousLineEmpty
      @_addLine ""

  _nextAnonymousClassName: ->
    className = "AnonymousClass" + (@anonymousClassCounter + 1)
    @anonymousClassCounter += 1
    className

  _getLiteralForValue: (value, typeName) ->
    if typeName is "String"
      # Escape string so that it can be included as a literal.
      # XXX: This assumes that the escaping rules for Java are the same as
      # those for JSON, which might not be true
      return "\"" + JSON.stringify(value).slice(1, -1) + "\""
    else
      return "#{value}"

  _printFields: (fieldAccesses) ->

    anonymousSpecs = []

    hasAtLeastOneFieldAccess = false
    for fieldName, fieldSpec of fieldAccesses
      hasAtLeastOneFieldAccess = true if fieldSpec.values.length > 0
    @_addPaddingLine() if hasAtLeastOneFieldAccess

    # Add an instance variable for the first access of each field
    for fieldName, fieldSpec of fieldAccesses
      if fieldSpec.values.length > 0

        firstValue = fieldSpec.values[0]
        typeString = undefined
        valueString = undefined

        if firstValue instanceof StubSpec
          typeString = @_nextAnonymousClassName()
          valueString = "new #{typeString}()"
          anonymousSpec = firstValue.copy()
          anonymousSpec.setClassName typeString
          anonymousSpecs.push anonymousSpec
        else
          if firstValue is null
            typeString = "Object"
          else
            typeString = fieldSpec.type
          valueString = @_getLiteralForValue firstValue, fieldSpec.type

        @_addLine "public #{typeString} #{fieldName} = #{valueString};"

    @_addPaddingLine() if hasAtLeastOneFieldAccess

    anonymousSpecs

  _getObjectKeyForMethodCall: (methodCall) ->
    methodCall.signature.name + "(" + \
      (methodCall.signature.argumentTypes.join ",") + ")"

  _printMethodBodies: (methodCalls, callCountNames) ->

    anonymousSpecs = []

    hasAtLeastOneMethodCall = false
    for methodCall in methodCalls
      hasAtLeastOneMethodCall = true if methodCall.returnValues.length > 0

    # Create methods that return all observed method return values
    for methodCall in methodCalls

      callCountName = callCountNames[@_getObjectKeyForMethodCall methodCall]
      signature = methodCall.signature
      methodName = signature.name
      returnType = signature.returnType
      argumentTypes = signature.argumentTypes
      returnValues = methodCall.returnValues

      continue if returnValues.length is 0

      @_addPaddingLine()

      # If this returns another stub, create a new return type and alter the
      # return values so they all return stub objects.
      returnsAnonymousClass = (returnType is "instance")
      returnTypeString = undefined
      returnValuesStrings = []
      if returnsAnonymousClass

        # Create a return type for a new stub object
        anonymousClassName = @_nextAnonymousClassName()
        returnTypeString = anonymousClassName

        nonNullReturns = returnValues.filter (value) => value?
        nonNullReturnValueCount = nonNullReturns.length

        # If there is more than one non-null return value for an anonymous class,
        # each returned stub needs to be a subclass of the anonymous class.
        if nonNullReturnValueCount > 1
          returnAnonymousSpec = new StubSpec anonymousClassName
          anonymousSpecs.push returnAnonymousSpec
          nonNullIndex = 0
          for returnValue in returnValues
            if returnValue is null
              returnValuesStrings.push "null"
            else
              returnObjectClassName = anonymousClassName + "_" + (nonNullIndex + 1)
              anonymousSpec = returnValue.copy()
              anonymousSpec.setClassName returnObjectClassName
              anonymousSpec.setSuperclassName anonymousClassName
              anonymousSpecs.push anonymousSpec
              returnValuesStrings.push "new #{returnObjectClassName}()"
              nonNullIndex += 1
        # Otherwise, we can return just one class, and a bunch of nulls
        else
          for returnValue in returnValues
            if returnValue is null
              returnValuesStrings.push "null"
            else
              returnValuesStrings.push "new #{anonymousClassName}()"
              anonymousSpec = returnValues[0].copy()
              anonymousSpec.setClassName anonymousClassName
              anonymousSpecs.push anonymousSpec

      else
        returnTypeString = returnType
        for returnValue in returnValues
          valueString = @_getLiteralForValue returnValue, returnType
          returnValuesStrings.push valueString

      argumentStrings = []
      for argumentType, i in argumentTypes
        argumentStrings.push "#{argumentTypes[i]} arg#{i + 1}"
      argumentsString = argumentStrings.join ", "

      @_addLine "public #{returnTypeString} #{methodName}(#{argumentsString}) {"
      @indentLevel += 1

      if returnValues.length == 1
        @_addLine "return #{returnValuesStrings[0]};"
      else if returnValues.length > 1
        for returnValue, i in returnValues
          conditionString = "#{callCountName} == #{i}"
          if i == 0
            @_addLine "if (#{conditionString}) {"
          else if i == returnValues.length - 1
            @_addLine "} else {"
          else
            @_addLine "} else if (#{conditionString}) {"
          @indentLevel += 1
          @_addLine "return #{returnValuesStrings[i]};"
          @indentLevel -= 1
          if i == returnValues.length - 1
            @_addLine "}"
        @_addLine "#{callCountName} += 1;"
      @indentLevel -= 1

      @_addLine "}"
      @_addPaddingLine()

    # @_addPaddingLine() if hasAtLeastOneMethodCall

    anonymousSpecs

  printToString: (stubSpec, options) ->

    # Load options from arguments
    defaultOptions =
      static: false
    options = _.merge {}, defaultOptions, options
    printClassesAsStatic = options.static

    # While we iterate through the spec, we might find nested specs
    # that we also have to print.  This list will keep track of them.
    anonymousSpecs = []

    # Print the start of the class declaration
    classDeclaration = "private "
    if printClassesAsStatic
      classDeclaration += "static "
    classDeclaration += "class " + stubSpec.getClassName()
    if stubSpec.getSuperclassName()?
      classDeclaration += (" extends " + stubSpec.getSuperclassName())
    classDeclaration += " {"
    @_addLine classDeclaration
    @indentLevel += 1

    fieldAnonymousSpecs = @_printFields stubSpec.getFieldAccesses()
    anonymousSpecs = anonymousSpecs.concat fieldAnonymousSpecs

    # Add counter variables for all methods that have multiple return values
    # First, find out which methods are overloaded
    methodNameCounts = {}
    for methodCall in stubSpec.getMethodCalls()
      methodName = methodCall.signature.name
      methodNameCounts[methodName] or= 0
      methodNameCounts[methodName] += 1

    # Then, assign distinct call count variables based on the signature
    callCountNames = {}
    anotherMethodNameCounter = {}
    printedCallCount = false

    for methodCall in stubSpec.getMethodCalls()

      # Build an initial call count name
      methodName = methodCall.signature.name
      anotherMethodNameCounter[methodName] or= 0

      # Modify the method counter name if there's more than one with the same name
      callCountName = undefined
      if methodNameCounts[methodName] > 1
        callCountName = "#{methodName}#{anotherMethodNameCounter[methodName] + 1}CallCount"
      else
        callCountName = "#{methodName}CallCount"

      # Finally, add a line declaring the call count for this method
      if methodCall.returnValues.length > 1
        if not printedCallCount
          @_addLine ""
          printedCallCount = true
        @_addLine "private int #{callCountName} = 0;"

      # Save the call count variable name so we can give it to the method printer
      key = @_getObjectKeyForMethodCall methodCall
      callCountNames[key] = callCountName
      anotherMethodNameCounter[methodName] += 1

    @_addPaddingLine() if printedCallCount

    methodAnonymousSpecs = @_printMethodBodies \
      stubSpec.getMethodCalls(), callCountNames
    anonymousSpecs = anonymousSpecs.concat methodAnonymousSpecs

    # Print the end of the class
    @indentLevel -= 1
    @_addLine "}"

    for spec in anonymousSpecs
      @_addLine ""
      @printToString spec, { static: printClassesAsStatic }

    @string
