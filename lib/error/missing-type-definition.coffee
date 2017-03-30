# For Java 1.8, imported from java.lang.*
AUTOMATICALLY_IMPORTED_TYPES = [
  "Object", "Boolean", "Comparable", "Serializable", "Character",
  "Comparable", "Serializable", "Character.Subset", "Character.UnicodeBlock",
  "Class", "AnnotatedElement", "GenericDeclaration", "Serializable", "Type",
  "ClassLoader", "ClassValue", "Compiler", "Enum", "Comparable",
  "Serializable", "Math", "Number", "Serializable", "Byte", "Comparable",
  "Double", "Comparable", "Float", "Comparable", "Integer", "Comparable",
  "Long", "Comparable", "Short", "Comparable", "Package", "AnnotatedElement",
  "Permission", "Guard", "Serializable", "BasicPermission", "Serializable",
  "RuntimePermission", "Process", "ProcessBuilder", "ProcessBuilder.Redirect",
  "Runtime", "SecurityManager", "StackTraceElement", "Serializable",
  "StrictMath", "String", "CharSequence", "Comparable", "Serializable",
  "StringBuffer", "CharSequence", "Serializable", "StringBuilder",
  "CharSequence", "Serializable", "System", "Thread", "Runnable",
  "ThreadGroup", "Thread.UncaughtExceptionHandler", "ThreadLocal",
  "InheritableThreadLocal", "Throwable", "Serializable", "Error",
  "AssertionError", "LinkageError", "BootstrapMethodError",
  "ClassCircularityError", "ClassFormatError", "UnsupportedClassVersionError",
  "ExceptionInInitializerError", "IncompatibleClassChangeError",
  "AbstractMethodError", "IllegalAccessError", "InstantiationError",
  "NoSuchFieldError", "NoSuchMethodError", "NoClassDefFoundError",
  "UnsatisfiedLinkError", "VerifyError", "ThreadDeath", "VirtualMachineError",
  "InternalError", "OutOfMemoryError", "StackOverflowError", "UnknownError",
  "Exception", "CloneNotSupportedException", "InterruptedException",
  "ReflectiveOperationException", "ClassNotFoundException",
  "IllegalAccessException", "InstantiationException", "NoSuchFieldException",
  "NoSuchMethodException", "RuntimeException", "ArithmeticException",
  "ArrayStoreException", "ClassCastException",
  "EnumConstantNotPresentException", "IllegalArgumentException",
  "IllegalThreadStateException", "NumberFormatException",
  "IllegalMonitorStateException", "IllegalStateException",
  "IndexOutOfBoundsException", "ArrayIndexOutOfBoundsException",
  "StringIndexOutOfBoundsException", "NegativeArraySizeException",
  "NullPointerException", "SecurityException", "TypeNotPresentException",
  "UnsupportedOperationException", "Void", "Appendable", "AutoCloseable",
  "CharSequence", "Cloneable", "Comparable", "Iterable", "Readable",
  "Runnable", "Thread.UncaughtExceptionHandler", "FunctionalInterface",
  "Annotation", "Deprecated", "Annotation", "Override", "Annotation",
  "SuppressWarnings", "Annotation", "SafeVarargs", "Annotation", "Object",
  "Enum", "Comparable", "Serializable", "Character.UnicodeScript",
  "Thread.State"
]


module.exports.MissingTypeDefinitionError = class MissingTypeDefinitionError

  constructor: (symbol) ->
    @symbol = symbol

  getSymbol: ->
    @symbol


module.exports.MissingTypeDefinitionDetector = class MissingTypeDefinitionDetector

  detectErrors: (model) ->

    importTable = model.getImportTable()
    activeImports = model.getImports()
    activeRanges = model.getRangeSet().getActiveRanges()
    classRanges = model.getRangeSet().getClassRanges()
    typeUses = model.getSymbols().getTypeUses()
    typeDefs = model.getSymbols().getTypeDefs()

    _getActiveSymbols = (symbolList) =>
      symbolList.filter (symbol) =>
        for activeRange in activeRanges
          return true if activeRange.containsRange symbol.getRange()
        return false

    usesInActiveRanges = _getActiveSymbols typeUses
    defsInActiveRanges = _getActiveSymbols typeDefs

    errors = []
    for use in usesInActiveRanges

      relatedDefsInActiveRanges = defsInActiveRanges.filter (def) =>
        (def.getFile() is use.getFile()) and (def.getName() is use.getName())

      relatedDefsInClassRanges = classRanges.filter (classRange) =>
        classSymbol = classRange.getSymbol()
        (classSymbol.getFile() is use.getFile()) and (classSymbol.getName() is use.getName())

      relatedImports = importTable.getImports use.getName()
      relatedActiveImports = []
      for relatedImport in relatedImports
        for activeImport in activeImports
          if relatedImport.equals activeImport
            relatedActiveImports.push relatedImport

      # Create an error if no appropriate def was found in the active ranges,
      # the class ranges, or the imports.
      relatedDefs = relatedDefsInActiveRanges.concat \
        relatedDefsInClassRanges, relatedActiveImports
      automaticallyImported = (use.getName() in AUTOMATICALLY_IMPORTED_TYPES) or
        ((use.getName().replace /java\.lang\./, '') in AUTOMATICALLY_IMPORTED_TYPES)
      if (relatedDefs.length is 0) and not automaticallyImported
        error = new MissingTypeDefinitionError use
        errors.push error

    errors
