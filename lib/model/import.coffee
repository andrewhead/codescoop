{ Range } = require "./range-set"


module.exports.Import = class Import

  constructor: (name, range) ->
    @name = name
    @range = range

  getName: ->
    @name

  getRange: ->
    @range

  equals: (other) ->
    (other instanceof Import) and
      (@name is other.getName()) and
      (@range.isEqual other.getRange())


# Map from class symbols to imports that define them
module.exports.ImportTable = class ImportTable

  constructor: ->
    @table = {}

  addImport: (fullyQualifiedClassName, import_) ->

    return if not fullyQualifiedClassName?

    shortName = fullyQualifiedClassName.replace /.*\./, ""
    lookupNames = [fullyQualifiedClassName, shortName]

    for name in lookupNames
      if name not of @table
        @table[name] = []

      importList = @table[name]
      if import_ not in importList
        sameImports = importList.filter (currentImport) =>
          currentImport.equals import_
        if sameImports.length is 0
          importList.push import_

  # Class can be either fully-qualified name or single token
  getImports: (className) ->
    @table[className] or []

  getFullyQualifiedName: (shortName) ->
    # If a fully-qualified name was already passed in, just return it
    if (shortName.indexOf '.') != -1
      return shortName
    # Otherwise, look for the first qualified name of an importd class that
    # ends with the class's short name
    for className of @table
      if className.endsWith ('.' + shortName)
        return className

  @deserialize: (json) ->

    table = new ImportTable()

    for className, matchingImports of json.table
      for importData in matchingImports
        importRange = new Range importData.range.start, importData.range.end
        import_ = new Import importData.name, importRange
        table.addImport className, import_

    return table
