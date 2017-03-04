{ InputStream, CommonTokenStream } = require 'antlr4'
{ JavaLexer } = require './grammars/Java/JavaLexer'
{ JavaParser } = require './grammars/Java/JavaParser'
{ JavaListener } = require './grammars/Java/JavaListener'
ParseTreeWalker = (require 'antlr4').tree.ParseTreeWalker.DEFAULT


class SymbolSearcher extends JavaListener

  constructor: (symbol) ->
    @symbol = symbol
    @matchingContexts = []

  visitTerminal: (node) ->

    nodeLine = node.symbol.line
    nodeStartColumn = node.symbol.column
    # In finding the node end column, we preseve the ANTLR convention of
    # having the end of the symbol be at the position of the last
    # character (rather than the one after it).  We correct by -1 in the
    # comparison below because our analysis ends a symbol on the character
    # that comes immediately after it.
    nodeEndColumn = nodeStartColumn + (node.symbol.stop - node.symbol.start)

    if (nodeLine is (@symbol.range.start.row + 1)) and
       (nodeStartColumn is @symbol.range.start.column) and
       (nodeEndColumn is (@symbol.range.end.column - 1)) and
       (node.symbol.text is @symbol.name)
      @matchingContexts.push node

  getMatchingCtx: ->
    if @matchingContexts.length > 1
      console.error "Warning: more than one matching ctx found for symbol. " +
        "This should never happen, and suggests something's strange with " +
        "this code, or the symbol you passed in."
    if @matchingContexts.length > 0 then @matchingContexts[0] else null


module.exports.parse = (codeText) ->

  # REUSE: This boilerplate for constructing a parse tree using ANTLR
  # is based on the snippet from the ANTLR4 project:
  # https://github.com/antlr/antlr4/blob/master/doc/javascript-target.md
  inputStream = new InputStream codeText
  lexer = new JavaLexer inputStream
  tokens = new CommonTokenStream lexer
  parser = new JavaParser tokens
  parser.buildParseTrees = true
  antlrTreeRootCtx = parser.compilationUnit()
  new ParseTree antlrTreeRootCtx


###
ANTLR lines are one-indexed, and columns are zero-indexed.  For the API of the
parse tree here, we use the convention of the GitHub Atom Range data structure:
lines and columns are both zero-indexed.
###
module.exports.ParseTree = class ParseTree

  constructor: (ctx) ->
    @root = ctx

  getRoot: ->
    @root

  # Search for the symbol in the tree, returning a node that corresponds
  # to it from the ANTLR parse tree.  Note that currently, this only works
  # for single identifiers (symbols that are terminal nodes in the tree)
  getNodeForSymbol: (symbol) ->
    symbolSearcher = new SymbolSearcher symbol
    ParseTreeWalker.walk symbolSearcher, @root
    symbolSearcher.getMatchingCtx()
