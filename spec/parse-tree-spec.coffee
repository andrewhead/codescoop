{ parse, ParseTree } = require "../lib/parse-tree"
{ JavaParser } = require "../lib/grammars/Java/JavaParser"
{ Symbol } = require "../lib/symbol-set"
{ Range } = require "atom"

JAVA_CODE = [
  "public class Example {"
  "  public static void main(String[] args) {"
  "    int i = 1;"
  "    {"
  "       int j = 2;"
  "       j = j + i;"
  "    }"
  "  }"
  "}"
].join "\n"


describe "parse", ->

  it "Parses Java code into a parse tree", ->
    tree = parse JAVA_CODE
    (expect tree instanceof ParseTree).toBe true


describe "ParseTree", ->

  tree = parse JAVA_CODE

  it "has a root that wraps the ANTLR 'context' of a Java program", ->
    (expect tree.getRoot().ruleIndex).toBe JavaParser.RULE_compilationUnit

  it "returns the node of the use of a symbol", ->
    symbol = new Symbol "nofile", "i", (new Range [2, 8], [2, 9])
    node = tree.getNodeForSymbol symbol
    (expect node.symbol.line).toBe 3
    (expect node.symbol.column).toBe 8
    (expect node.symbol.stop - node.symbol.start).toBe 0

  it "returns null when the name of the symbol is incorrect", ->
    symbol = new Symbol "nofile", "N", (new Range [2, 8], [2, 9])
    node = tree.getNodeForSymbol symbol
    (expect node).toBeNull()

  xit "returns null when the position of a symbol is incorrect", ->
    symbol = new Symbol "nofile", "i", (new Range [3, 8], [3, 9])
    node = tree.getNodeForSymbol symbol
    (expect node).toBeNull()