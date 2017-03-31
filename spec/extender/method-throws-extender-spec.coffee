{ MethodThrowsEvent } = require "../../lib/event/method-throws"
{ ControlCrossingEvent } = require "../../lib/event/control-crossing"
{ MethodThrowsExtender } = require "../../lib/extender/method-throws-extender"
{ File, Symbol } = require "../../lib/model/symbol-set"
{ Range } = require "../../lib/model/range-set"
{ partialParse } = require "../../lib/analysis/parse-tree"


describe "MethodThrowsExtender", ->

  extension = undefined
  testFile = undefined
  beforeEach =>
    testFile = new File "path", "file_name"
    extender = new MethodThrowsExtender()
    methodCtx = partialParse ([
      "public void errorProne() throws IOException {"
      "  int i;"
      "}"
    ].join "\n"), "classBodyDeclaration"
    event = new MethodThrowsEvent "IOException",
      methodCtx, new Range [1, 2], [1, 8]
    extension = extender.getExtension event

  it "includes the range for the method header", ->
    (expect extension.getMethodHeaderRange()).toEqual new Range [0, 0], [0, 43]
    (expect extension.getEvent()).toBe event

  it "includes the range of the throws symbol", ->
    (expect extension.getThrowsRange()).toEqual new Range [0, 25], [0, 31]

  it "includes the range of the throwable", ->
    (expect extension.getThrowableRange()).toEqual new Range [0, 32], [0, 43]

  it "includes the range that was initially added to the snippets", ->
    (expect extension.getInnerRange()).toEqual new Range [1, 2], [1, 8]
