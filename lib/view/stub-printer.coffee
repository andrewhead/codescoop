{ StubSpec } = require "../model/stub-spec"


# Currently, a new stub printer needs to be created for every stub that
# gets printed, due to the printer's internal state.
module.exports.StubPrinter = class StubPrinter

  TAB_LENGTH: 4

  constructor: ->
    @string = ""
    @anonymousClassCounter = 0
    @indentLevel = 0

  _addLine: (string) ->

    # Print spaces for all tabs at this indent level
    @string += (Array (@indentLevel * @TAB_LENGTH + 1)).join " "

    # Print the string
    @string += (string + "\n")

  _nextAnonymousClassName: ->
    className = "AnonymousClass" + (@anonymousClassCounter + 1)
    @anonymousClassCounter += 1
    className

  _printFields: (fieldAccesses) ->

    anonymousSpecs = []

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
          typeString = fieldSpec.type
          valueString = "#{firstValue}"

        @_addLine "public #{typeString} #{fieldName} = #{valueString};"

    anonymousSpecs

  _getObjectKeyForMethodCall: (methodCall) ->
    methodCall.signature.name + "(" + \
      (methodCall.signature.argumentTypes.join ",") + ")"

  _printMethodBodies: (methodCalls, callCountNames) ->

    anonymousSpecs = []

    # Create methods that return all observed method return values
    for methodCall in methodCalls

      callCountName = callCountNames[@_getObjectKeyForMethodCall methodCall]
      signature = methodCall.signature
      methodName = signature.name
      returnType = signature.returnType
      argumentTypes = signature.argumentTypes
      returnValues = methodCall.returnValues

      continue if returnValues.length is 0

      # If this returns another stub, create a new return type and alter the
      # return values so they all return stub objects.
      returnsAnonymousClass = (returnType is "instance")
      returnTypeString = undefined
      returnValuesStrings = []
      if returnsAnonymousClass

        # Create a return type for a new stub object
        anonymousClassName = @_nextAnonymousClassName()
        returnTypeString = anonymousClassName

        # If there is more than one return value for an anonymous class,
        # each returned stub needs to be a subclass of the anonymous class.
        if returnValues.length > 1
          returnAnonymousSpec = new StubSpec anonymousClassName
          anonymousSpecs.push returnAnonymousSpec
          for returnValue, i in returnValues
            returnObjectClassName = anonymousClassName + "_" + (i + 1)
            anonymousSpec = returnValue.copy()
            anonymousSpec.setClassName returnObjectClassName
            anonymousSpec.setSuperclassName anonymousClassName
            anonymousSpecs.push anonymousSpec
            returnValuesStrings.push "new #{returnObjectClassName}()"
        # Otherwise, we can return just one class
        else
          returnValuesStrings = ["new #{anonymousClassName}()"]
          anonymousSpec = returnValues[0].copy()
          anonymousSpec.setClassName anonymousClassName
          anonymousSpecs.push anonymousSpec

      else
        returnTypeString = returnType
        returnValuesStrings = ("#{returnValue}" for returnValue in returnValues)

      argumentStrings = []
      for _, i in argumentTypes
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

    anonymousSpecs

  printToString: (stubSpec) ->

    # While we iterate through the spec, we might find nested specs
    # that we also have to print.  This list will keep track of them.
    anonymousSpecs = []

    # Print the start of the class declaration
    classDeclaration = "private class " + stubSpec.getClassName()
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
        @_addLine "private int #{callCountName} = 0;"

      # Save the call count variable name so we can give it to the method printer
      key = @_getObjectKeyForMethodCall methodCall
      callCountNames[key] = callCountName
      anotherMethodNameCounter[methodName] += 1

    methodAnonymousSpecs = @_printMethodBodies \
      stubSpec.getMethodCalls(), callCountNames
    anonymousSpecs = anonymousSpecs.concat methodAnonymousSpecs

    # Print the end of the class
    @indentLevel -= 1
    @_addLine "}"

    for spec in anonymousSpecs
      @_addLine ""
      @printToString spec

    @string
