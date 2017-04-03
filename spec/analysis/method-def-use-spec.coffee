{ MethodDefUseAnalysis } = require "../../lib/analysis/method-def-use"
{ MethodUseFinder, MethodDefFinder } = require "../../lib/analysis/method-def-use"
{ File, Symbol } = require "../../lib/model/symbol-set"
{ parse } = require "../../lib/analysis/parse-tree"
{ Range } = require "../../lib/model/range-set"


describe "MethodDefUseAnalysis", ->

  it "calls a callback with the defs and uses found once finished", ->

    testFile = new File "path", "filename"
    code = [
      "public class Example {"
      "  public void recurse() {"
      "    recurse();"
      "  }"
      "}"
    ].join "\n"
    parseTree = parse code
    analysis = new MethodDefUseAnalysis testFile, parseTree

    result = undefined
    runs =>
      analysis.run (analysisResult) =>
        result = analysisResult
    waitsFor =>
      result
    runs =>
      uses = result.methodUses
      defs = result.methodDefs
      (expect uses.length).toBe 1
      (expect uses[0].getRange()).toEqual new Range [2, 4], [2, 11]
      (expect defs.length).toBe 1
      (expect defs[0].getRange()).toEqual new Range [1, 14], [1, 21]


describe "MethodUseFinder", ->

  testFile = new File "path", "filename"
  methodUseFinder = new MethodUseFinder testFile

  _checkForOneTypeSymbol = (parseTree, symbolName, range) =>
    methodUses = methodUseFinder.findMethodUses parseTree
    (expect methodUses.length).toBe 1
    (expect methodUses[0]).toEqual \
      new Symbol testFile, symbolName, range, "Method"

  it "finds method uses used to define class members", ->
    parseTree = parse [
      "public class Example {"
      "  int i = method();"
      "  public int method() { return 42; }"
      "}"
    ].join "\n"
    _checkForOneTypeSymbol parseTree, "method", new Range [1, 10], [1, 16]

  it "finds method uses within other methods", ->
    parseTree = parse [
      "public class Example {"
      "  public void method() {"
      "    method();"
      "  }"
      "}"
    ].join "\n"
    _checkForOneTypeSymbol parseTree, "method", new Range [2, 4], [2, 10]

  it "ignores method uses made on objects", ->
    parseTree = parse [
      "public class Example {"
      "  public void method() {"
      "    Object o = new Object();"
      "    o.toString();"
      "  }"
      "}"
    ].join "\n"
    methodUses = methodUseFinder.findMethodUses parseTree
    (expect methodUses.length).toBe 0

  it "ignores method uses made on classes", ->
    parseTree = parse [
      "public class Example {"
      "  public void method() {"
      "    System.out.println(\"\");"
      "  }"
      "}"
    ].join "\n"
    methodUses = methodUseFinder.findMethodUses parseTree
    (expect methodUses.length).toBe 0

  it "ignores `this` and `super`", ->
    parseTree = parse [
      "public class Example {"
      "  public Example () { this(); }"
      "  public void method() { super(); }"
      "}"
    ].join "\n"
    methodUses = methodUseFinder.findMethodUses parseTree
    (expect methodUses.length).toBe 0


describe "MethodDefFinder", ->

  testFile = new File "path", "filename"
  methodDefFinder = new MethodDefFinder testFile

  _checkForOneTypeSymbol = (parseTree, symbolName, range) =>
    methodDefs = methodDefFinder.findMethodDefs parseTree
    (expect methodDefs.length).toBe 1
    (expect methodDefs[0]).toEqual \
      new Symbol testFile, symbolName, range, "Method"

  it "finds method definitions within class declarations", ->
    parseTree = parse [
      "public class Example {"
      "  public void method() {}"
      "}"
    ].join "\n"
    _checkForOneTypeSymbol parseTree, "method", new Range [1, 14], [1, 20]
