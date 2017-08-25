{ File, createSymbol } = require "../../lib/model/symbol-set"
{ parse } = require "../../lib/analysis/parse-tree"
{ extractForLoopDefs } = require "../../lib/analysis/for-loop-variable-def"


describe "extractForLoopDefs", ->

  _createIntSymbol = (name, startPoint, endPoint) =>
    createSymbol "path/", "filename", name, startPoint, endPoint, "int"

  it "detects variable definitions in for-loops", ->
    code = [
      "public class Example {"
      "  public static void main(String[] args) {"
      "    for (int i = 0, j = 2;;) {}"
      "  }"
      "}"
    ].join "\n"
    parseTree = parse code
    defs = extractForLoopDefs (new File "path/", "filename"), parseTree
    (expect defs.length).toBe 2
    (expect defs[0].equals (_createIntSymbol "i", [2, 13], [2, 14])).toBe true
    (expect defs[1].equals (_createIntSymbol "j", [2, 20], [2, 21])).toBe true

  it "ignores declarations without a definition", ->
    code = [
      "public class Example {"
      "  public static void main(String[] args) {"
      "    for (int i;;) {}"
      "  }"
      "}"
    ].join "\n"
    parseTree = parse code
    defs = extractForLoopDefs (new File "path/", "filename"), parseTree
    (expect defs.length).toBe 0
