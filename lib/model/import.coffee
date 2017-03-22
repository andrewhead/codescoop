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
