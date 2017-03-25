{ Agent } = require "../../lib/agent/agent"
{ acceptOnlyForLoopsAndTryBlocks } = require "../../lib/agent/agent"
{ ExampleModel, ExampleModelState } = require "../../lib/model/example-model"
{ ControlStructureExtension } = require "../../lib/extender/control-structure-extender"
{ IfControlStructure, ForControlStructure, WhileControlStructure, DoWhileControlStructure, TryCatchControlStructure } = require "../../lib/analysis/parse-tree"


describe "Agent", ->

  describe "when the model enters the ERROR_CHOICE state", ->

    model = undefined
    agent = undefined

    beforeEach =>
      model = new ExampleModel()
      agent = new Agent model
      agent.chooseError = => { errorId: 42 }
      (spyOn agent, "chooseError").andCallThrough()

    it "calls chooseError when the ERROR_CHOICE state is entered", ->
      (expect agent.chooseError).not.toHaveBeenCalled()
      model.setState ExampleModelState.ERROR_CHOICE
      (expect agent.chooseError).toHaveBeenCalled()

    it "passes the list of errors as arguments to chooseError", ->
      errorList = [{ errorId: 41, errorId: 42 }]
      model.setErrors errorList
      model.setState ExampleModelState.ERROR_CHOICE
      (expect agent.chooseError).toHaveBeenCalledWith errorList

    it "sets the model's error choice to the one returned by chooseError", ->
      model.setState ExampleModelState.ERROR_CHOICE
      (expect model.getErrorChoice()).toEqual { errorId: 42 }

  describe "when the model enters the RESOLUTION state", ->

    model = undefined
    agent = undefined

    beforeEach =>
      model = new ExampleModel()
      agent = new Agent model
      agent.chooseResolution = => { resolutionId: 42 }
      (spyOn agent, "chooseResolution").andCallThrough()

    it "calls chooseResolution when the RESOLUTION state is entered", ->
      (expect agent.chooseResolution).not.toHaveBeenCalled()
      model.setState ExampleModelState.RESOLUTION
      (expect agent.chooseResolution).toHaveBeenCalled()

    it "passes the list of resolutions as arguments to chooseResolution", ->
      resolutionList = [{ resolutionId: 41, resolutionId: 42 }]
      model.setSuggestions resolutionList
      model.setState ExampleModelState.RESOLUTION
      (expect agent.chooseResolution).toHaveBeenCalledWith resolutionList

    it "sets the model's resolution choice to the one returned by " +
        "chooseResolution", ->
      model.setState ExampleModelState.RESOLUTION
      (expect model.getResolutionChoice()).toEqual { resolutionId: 42 }

  describe "when the model enters the EXTENSION state", ->

    model = undefined
    agent = undefined

    beforeEach =>
      model = new ExampleModel()
      agent = new Agent model
      agent.acceptExtension = => false
      (spyOn agent, "acceptExtension").andCallThrough()

    it "calls acceptExtension when the EXTENSION state is entered", ->
      (expect agent.acceptExtension).not.toHaveBeenCalled()
      model.setState ExampleModelState.EXTENSION
      (expect agent.acceptExtension).toHaveBeenCalled()

    it "passes the proposed extension as an argument to acceptExtension", ->
      extension = { extensionId: 41 }
      model.setProposedExtension extension
      model.setState ExampleModelState.EXTENSION
      (expect agent.acceptExtension).toHaveBeenCalledWith extension

    it "sets the model's extension result to the one returned by acceptExtension", ->
      model.setState ExampleModelState.EXTENSION
      (expect model.getExtensionDecision()).toEqual false


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
