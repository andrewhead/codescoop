{ acceptOnlyForLoopsAndTryBlocks } = require "../../lib/agent/policies"
{ chooseFirstError } = require "../../lib/agent/policies"
{ ControlStructureExtension } = require "../../lib/extender/control-structure-extender"
{ IfControlStructure, ForControlStructure, WhileControlStructure, DoWhileControlStructure, TryCatchControlStructure } = require "../../lib/analysis/parse-tree"


describe "chooseFirstError", ->

  it "chooses the first error given in the list of errors", ->
    chosenError = chooseFirstError [{ errorId: 42 }, { errorId: 43 }]
    (expect chosenError).toEqual { errorId: 42 }


describe "acceptOnlyForLoopsAndTryBlocks", ->

  # For each of the following tests, we're being lazy and not initializing most
  # of the fields for the control structure extension and control structure.
  # This is mostly to keep the test readable and maintainable.
  it "accepts extensions for \"for\" loops", ->
    extension = new ControlStructureExtension new ForControlStructure()
    (expect acceptOnlyForLoopsAndTryBlocks extension).toBe true

  it "accepts extensions for try-catch blocks", ->
    extension = new ControlStructureExtension new TryCatchControlStructure()
    (expect acceptOnlyForLoopsAndTryBlocks extension).toBe true

  it "rejects extensions for while loops", ->
    extension = new ControlStructureExtension new WhileControlStructure()
    (expect acceptOnlyForLoopsAndTryBlocks extension).toBe false

  it "rejects extensions for do-while loops", ->
    extension = new ControlStructureExtension new DoWhileControlStructure()
    (expect acceptOnlyForLoopsAndTryBlocks extension).toBe false

  it "rejects extensions for if statements", ->
    extension = new ControlStructureExtension new IfControlStructure()
    (expect acceptOnlyForLoopsAndTryBlocks extension).toBe false

  it "rejects an extension that is not a control structure", ->
    extension = {}
    (expect acceptOnlyForLoopsAndTryBlocks extension).toBe false
