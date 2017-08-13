{ Import, ImportTable } = require "../model/import"
{ JavaParser } = require "../grammar/Java/JavaParser"
{ JavaListener } = require "../grammar/Java/JavaListener"
ParseTreeWalker = (require "antlr4").tree.ParseTreeWalker.DEFAULT
{ parse } = require "../../lib/analysis/parse-tree"
{ Range } = require "../../lib/model/range-set"
{ java } = require "../config/paths"
fs = require "fs"
ImportAnalysisJ = java.import "ImportAnalysis"


class ImportVisitor extends JavaListener

  constructor: ->
    @importCtxs = []

  enterImportDeclaration: (ctx) ->
    @importCtxs.push ctx

  getImportCtxs: ->
    @importCtxs


module.exports.ImportFinder = class ImportFinder

  findImports: (code) ->

    imports = []

    # Get all of the ctx's from the parse tree corresponding to imports
    parseTree = parse code
    importVisitor = new ImportVisitor()
    ParseTreeWalker.walk importVisitor, parseTree.getRoot()
    importCtxs = importVisitor.getImportCtxs()

    for importCtx in importCtxs

      nameChild = importCtx.children[1]
      childBeforeSemicolon = importCtx.children[importCtx.children.length - 2]

      _getStopColumnOnLine = (ctx) ->
        if "symbol" of ctx
          stopColumnOnLine = ctx.symbol.column +
            (ctx.symbol.stop - ctx.symbol.start)
        else
          stopColumnOnLine = ctx.stop.column +
            (ctx.stop.stop - ctx.stop.start)
        stopColumnOnLine

      _getLastCharacterIndex = (ctx) ->
        if "symbol" of ctx
          lastCharacterIndex = ctx.symbol.stop
        else
          lastCharacterIndex = ctx.stop.stop
        lastCharacterIndex

      # Create a range that corresponds to the imported name
      lineNumber = nameChild.start.line
      lineFirstCharacterIndex = nameChild.start.column
      lineLastCharacterIndex = _getStopColumnOnLine childBeforeSemicolon
      range = new Range [lineNumber - 1, lineFirstCharacterIndex],
        [lineNumber - 1, lineLastCharacterIndex + 1]

      # Extract the imported name from the code text
      firstCharacterIndex = nameChild.start.start
      lastCharacterIndex = _getLastCharacterIndex childBeforeSemicolon
      name = code.substring firstCharacterIndex, lastCharacterIndex + 1

      import_ = new Import name, range
      imports.push import_

    imports


module.exports.ImportAnalysis = class ImportAnalysis

  constructor: (file) ->
    @file = file

  run: (callback, err) ->

    fs.readFile @file.getPath(), (fileError, data) =>

      if fileError?
        err fileError
        return

      importTable = new ImportTable()

      # Find all imports in the current code
      importFinder = new ImportFinder()
      code = data.toString()
      imports = importFinder.findImports code

      # Run analysis to find which classes are provided by each import
      # Perform analyses for each import sequentially, so that we don't have
      # to worry about synchronous access to the import table
      analysisJ = new ImportAnalysisJ()
      analysisDone = Promise.resolve()
      for import_ in imports
        analysisDone = analysisDone.then (() ->
          new Promise (resolve, reject) =>
            importName = @.getName()
            classes = analysisJ.getClassNames importName, (javaErr, classNamesJ) =>
              if javaErr
                err javaErr
                return
              for className in classNamesJ.toArraySync()
                importTable.addImport className, @
              resolve()
          ).bind import_

      # Once analysis has been run for all imports, then we return the imports
      analysisDone.then =>
        callback importTable
