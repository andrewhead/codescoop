{ JavaLexer } = require '../grammar/Java/JavaLexer'
{ JavaParser } = require '../grammar/Java/JavaParser'
{ JavaListener } = require '../grammar/Java/JavaListener'
{ InputStream, CommonTokenStream } = require 'antlr4'
{ Range } = require "../model/range-set"
ParseTreeWalker = (require 'antlr4').tree.ParseTreeWalker.DEFAULT


module.exports.ControlStructure = class ControlStructure

  constructor: (ctx) ->
    @ctx = ctx

  getCtx: ->
    @ctx


module.exports.IfControlStructure = class IfControlStructure extends ControlStructure
module.exports.ForControlStructure = class ForControlStructure extends ControlStructure
module.exports.DoWhileControlStructure = class DoWhileControlStructure extends ControlStructure
module.exports.WhileControlStructure = class WhileControlStructure extends ControlStructure
module.exports.TryCatchControlStructure = class TryCatchControlStructure extends ControlStructure


# Create a control structure object that indicates the type of the
# control structure for this ctx.  Return null if it isn't a control structure.
module.exports.toControlStructure = toControlStructure = (ctx) ->

  # The ctxs for all of the control structures share some similar structural
  # features.  In particular, their first child is a symbol.  For readability,
  # we consolidate that check up here.
  if (ctx.children.length is 0) or ("symbol" not of ctx.children[0])
    return null

  # Given the structure of our Java grammar, we can just look at the
  # text of the first symbol to tell which type of control structure this is
  firstChildText = ctx.children[0].symbol.text
  return (new IfControlStructure ctx) if firstChildText is "if"
  return (new ForControlStructure ctx) if firstChildText is "for"
  return (new DoWhileControlStructure ctx) if firstChildText is "do"
  return (new WhileControlStructure ctx) if firstChildText is "while"
  return (new TryCatchControlStructure ctx) if firstChildText is "try"

  # If none of the above patterns match, return null
  null


module.exports.extractCtxRange = extractCtxRange = (ctx) ->

  # Check to see that this is actually a ctx.
  if not ("symbol" of ctx)
    ctxStart = ctx.start
    ctxStop = ctx.stop
    return new Range [ctxStart.line - 1, ctxStart.column],
      [ctxStop.line - 1, ctxStop.column + (ctxStop.stop - ctxStop.start) + 1]

  # If not, this is a symbol node, and we can still extrat the range
  else
    node = ctx
    symbol = node.symbol
    return new Range [symbol.line - 1, symbol.column],
      [symbol.line - 1, symbol.column + (symbol.stop - symbol.start) + 1]


class CtxSearcher extends JavaListener

  constructor: (range) ->
    @range = range

  # With post-order traversal, we consider ctxs from smallest to largest,
  # guaranteeing to return the smallest node that could contain the range.
  exitEveryRule: (ctx) ->
    if not @ctx?
      ctxRange = extractCtxRange ctx
      if (ctxRange.containsRange @range) and not @ctx?
        @ctx = ctx

  getCtx: ->
    @ctx


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

    if (nodeLine is (@symbol.getRange().start.row + 1)) and
       (nodeStartColumn is @symbol.getRange().start.column) and
       (nodeEndColumn is (@symbol.getRange().end.column - 1)) and
       (node.symbol.text is @symbol.getName())
      @matchingContexts.push node

  getMatchingCtx: ->
    if @matchingContexts.length > 1
      console.error "Warning: more than one matching ctx found for symbol. " +
        "This should never happen, and suggests something's strange with " +
        "this code, or the symbol you passed in."
    if @matchingContexts.length > 0 then @matchingContexts[0] else null


# During testing, we don't always want the parse for the full program.  This
# method let's us do a parse starting starting at a specific rule
module.exports.partialParse = partialParse = (codeText, ruleName) ->

  # REUSE: This boilerplate for constructing a parse tree using ANTLR
  # is based on the snippet from the ANTLR4 project:
  # https://github.com/antlr/antlr4/blob/master/doc/javascript-target.md
  inputStream = new InputStream codeText
  lexer = new JavaLexer inputStream
  tokens = new CommonTokenStream lexer
  parser = new JavaParser tokens
  parser.buildParseTrees = true
  ctx = parser[ruleName]()


module.exports.parse = (codeText) ->
  ctx = partialParse codeText, "compilationUnit"
  new ParseTree ctx


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

  getCtxForRange: (range) ->
    ctxSearcher = new CtxSearcher range
    ParseTreeWalker.walk ctxSearcher, @root
    ctxSearcher.getCtx()
