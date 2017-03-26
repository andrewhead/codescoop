{ Agent } = require "../../lib/agent/agent"
{ ExampleModel, ExampleModelState } = require "../../lib/model/example-model"


describe "Agent", ->

  describe "when asked explicitly to run", ->

    model = undefined

    beforeEach =>
      model = new ExampleModel()

    it "chooses an error when the model is in ERROR_CHOICE state", ->

      # Create agent after the model is already in the ERROR_CHOICE state.
      # If we create it before, it will run in response to the model change.
      model.setState ExampleModelState.ERROR_CHOICE
      agent = new Agent model
      agent.chooseError = => { errorId: 42 }
      (spyOn agent, "chooseError").andCallThrough()

      (expect agent.chooseError).not.toHaveBeenCalled()
      agent.run()
      (expect agent.chooseError).toHaveBeenCalled()

    it "chooses a resolution when the model is in RESOLUTION state", ->

      model.setState ExampleModelState.RESOLUTION
      agent = new Agent model
      agent.chooseResolution = => { resolutionId: 42 }
      (spyOn agent, "chooseResolution").andCallThrough()

      (expect agent.chooseResolution).not.toHaveBeenCalled()
      agent.run()
      (expect agent.chooseResolution).toHaveBeenCalled()

    it "makes a decision when the model is in EXTENSION state", ->

      model.setState ExampleModelState.EXTENSION
      agent = new Agent model
      agent.acceptExtension = => false
      (spyOn agent, "acceptExtension").andCallThrough()

      (expect agent.acceptExtension).not.toHaveBeenCalled()
      agent.run()
      (expect agent.acceptExtension).toHaveBeenCalled()

  it "stops listening for events when deactivated", ->
    model = new ExampleModel()
    agent = new Agent model
    agent.chooseError = => { errorId: 42 }
    (spyOn agent, "chooseError").andCallThrough()
    agent.deactivate()
    model.setState ExampleModelState.ERROR_CHOICE
    (expect agent.chooseError).not.toHaveBeenCalled()

  it "starts listening for events when reactivated", ->
    model = new ExampleModel()
    agent = new Agent model
    agent.chooseError = => { errorId: 42 }
    (spyOn agent, "chooseError").andCallThrough()
    agent.deactivate()
    agent.activate()
    model.setState ExampleModelState.ERROR_CHOICE
    (expect agent.chooseError).toHaveBeenCalled()

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
