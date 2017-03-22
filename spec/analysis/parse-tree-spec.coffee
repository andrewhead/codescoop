{ parse, partialParse, ParseTree } = require "../../lib/analysis/parse-tree"
{ JavaParser } = require "../../lib/grammar/Java/JavaParser"
{ Symbol, File } = require "../../lib/model/symbol-set"
{ Range } = require "../../lib/model/range-set"
{ toControlStructure, ControlStructure } = require "../../lib/analysis/parse-tree"
{ IfControlStructure, ForControlStructure, DoWhileControlStructure, WhileControlStructure, TryCatchControlStructure } = require "../../lib/analysis/parse-tree"

JAVA_CODE = [
  "public class Example {"
  "  public static void main(String[] args) {"
  "    int i = 1;"
  "  }"
  "}"
].join "\n"


describe "parse", ->

  it "Parses Java code into a parse tree", ->
    tree = parse JAVA_CODE
    (expect tree instanceof ParseTree).toBe true


describe "ParseTree", ->

  fakeFile = new File ".", "E.java"
  tree = parse JAVA_CODE

  it "has a root that wraps the ANTLR 'context' of a Java program", ->
    (expect tree.getRoot().ruleIndex).toBe JavaParser.RULE_compilationUnit

  it "returns the node of the use of a symbol", ->
    symbol = new Symbol fakeFile, "i", (new Range [2, 8], [2, 9])
    node = tree.getNodeForSymbol symbol
    (expect node.symbol.line).toBe 3
    (expect node.symbol.column).toBe 8
    (expect node.symbol.stop - node.symbol.start).toBe 0

  it "returns null when the name of the symbol is incorrect", ->
    symbol = new Symbol fakeFile, "N", (new Range [2, 8], [2, 9])
    node = tree.getNodeForSymbol symbol
    (expect node).toBeNull()

  it "returns null when the position of a symbol is incorrect", ->
    symbol = new Symbol fakeFile, "i", (new Range [3, 8], [3, 9])
    node = tree.getNodeForSymbol symbol
    (expect node).toBeNull()

  it "finds the smallest ctx that contains a range", ->
    range = new Range [2, 5], [2, 7]  # "nt" in Line 2: "int i = 1;"
    ctx = tree.getCtxForRange range
    (expect ctx.ruleIndex).toBe JavaParser.RULE_primitiveType


describe "toControlStructure", ->

  it "returns null if the ctx is not a control structure", ->
    structure = toControlStructure partialParse "i = i + 1;", "statement"
    (expect structure).toBe null

  it "creates an \"if\" control structure for an if ctx", ->
    structure = toControlStructure partialParse "if (true) {}", "statement"
    (expect structure instanceof IfControlStructure).toBe true

  it "creates a \"for\" control structure for a for ctx", ->
    structure = toControlStructure partialParse "for (;;) {}", "statement"
    (expect structure instanceof ForControlStructure).toBe true

  it "creates a \"do-while\" structure for a do-while ctx", ->
    structure = toControlStructure partialParse "do {} while (true);", "statement"
    (expect structure instanceof DoWhileControlStructure).toBe true

  it "creates a \"while\" structure for a while ctx", ->
    structure = toControlStructure partialParse "while (true) {}", "statement"
    (expect structure instanceof WhileControlStructure).toBe true

  it "creates a \"try\" structure for a try-catch ctx", ->
    structure = toControlStructure partialParse "try {} catch (Exception e) {}", "statement"
    (expect structure instanceof TryCatchControlStructure).toBe true
