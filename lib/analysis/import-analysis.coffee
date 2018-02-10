{ Import, ImportTable } = require "../model/import"
{ JavaParser } = require "../grammar/Java/JavaParser"
{ JavaListener } = require "../grammar/Java/JavaListener"
ParseTreeWalker = (require "antlr4").tree.ParseTreeWalker.DEFAULT
{ parse } = require "../../lib/analysis/parse-tree"
{ Range } = require "../../lib/model/range-set"
{ loadJson } = require "../config/paths"


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
    loadJson @file.getName(), "ImportTable", (error, json) =>
      err error if error
      callback ImportTable.deserialize json
