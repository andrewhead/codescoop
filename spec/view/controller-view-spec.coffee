{ ExampleController } = require "../../lib/example-controller"
{ ExampleModel, ExampleModelState } = require "../../lib/model/example-model"
{ ControllerView } = require "../../lib/view/controller-view"
{ CommandStack } = require "../../lib/command/command-stack"
{ Range } = require "../../lib/model/range-set"


describe "ControllerView", ->

  model = undefined
  exampleController = undefined
  controllerView = undefined
  exampleEditor = undefined
  commandStack = undefined

  beforeEach =>
    model = new ExampleModel()
    commandStack = new CommandStack()
    waitsForPromise =>
      atom.workspace.open "ExampleFile"
    runs =>
      exampleEditor = atom.workspace.getActiveTextEditor()
      exampleEditor.setText [
        "int temp = 1;"
      ].join "\n"
      exampleController = new ExampleController model, { commandStack }
      controllerView = new ControllerView exampleController, model, exampleEditor

  it "passes on an undo event when the undo button is clicked", ->
    undoButton = controllerView.find "#undo-button"
    (spyOn exampleController, "undo").andCallThrough()
    (expect exampleController.undo).not.toHaveBeenCalled()
    undoButton.click()
    (expect exampleController.undo).toHaveBeenCalled()

  it "disables the undo button when there are no commands on the stack", ->
    undoButton = controllerView.find "#undo-button"
    (expect undoButton.attr "disabled").toBe "disabled"
    commandStack.push { fakeCommand: "fakeCommand" }
    (expect undoButton.attr "disabled").toBe undefined

  it "enables the undo button when there is a command on the stack", ->
    commandStack.push { fakeCommand: "fakeCommand" }
    undoButton = controllerView.find "#undo-button"
    (expect undoButton.attr "disabled").toBe undefined
    commandStack.pop()
    (expect undoButton.attr "disabled").toBe "disabled"

  it "enables the print button when text is selected in the example editor", ->
    printButton = controllerView.find "#print-symbol-button"
    (expect printButton.attr "disabled").toBe "disabled"
    selectedRange = new Range [0, 4], [0, 8]
    exampleEditor.setSelectedBufferRange selectedRange
    (expect printButton.attr "disabled").toBe undefined

  it "disables the print button when the example editor has no selection", ->
    selectedRange = new Range [0, 4], [0, 8]
    exampleEditor.setSelectedBufferRange selectedRange
    printButton = controllerView.find "#print-symbol-button"
    (expect printButton.attr "disabled").toBe undefined
    exampleEditor.clearSelections()
    (expect printButton.attr "disabled").toBe "disabled"

  it "adds a range when someone clicks the print button", ->
    (spyOn exampleController, "addPrintedSymbol").andCallThrough()
    (expect exampleController.addPrintedSymbol).not.toHaveBeenCalled()

    # Choose a range of text and click the 'print symbol' button
    selectedRange = new Range [0, 4], [0, 8]
    exampleEditor.setSelectedBufferRange selectedRange
    printButton = controllerView.find "#print-symbol-button"
    printButton.click()

    (expect exampleController.addPrintedSymbol).toHaveBeenCalledWith "temp"

  it "issues a run-script command when the run button is clicked", ->
    runButton = controllerView.find "#run-button"
    issuedRunCommand = false
    atom.commands.onDidDispatch (event) =>
      if event.type == "script:run"
        issuedRunCommand = true
    runButton.click()
    waitsFor =>
      issuedRunCommand

  it "disables the run button when the model is analyzing", ->
    runButton = controllerView.find "#run-button"
    model.setState ExampleModelState.ANALYSIS
    (expect runButton.attr "disabled").toBe "disabled"

  it "enables the run button when the model leaves the analysis state", ->
    runButton = controllerView.find "#run-button"
    model.setState ExampleModelState.IDLE
    (expect runButton.attr "disabled").toBe undefined

  it "disables the run button when focus leaves the example editor", ->
    runButton = controllerView.find "#run-button"
    model.setState ExampleModelState.IDLE
    (expect runButton.attr "disabled").toBe undefined
    # This should activate another item that isn't the example editor
    waitsForPromise =>
      atom.workspace.open "OtherFile"
    runs =>
      (expect runButton.attr "disabled").toBe "disabled"

  it "disables the run button when focus returns to the example editor", ->
    runButton = controllerView.find "#run-button"
    model.setState ExampleModelState.IDLE
    waitsForPromise =>
      atom.workspace.open "OtherFile"
    waitsForPromise =>
      atom.workspace.open "ExampleFile"
    runs =>
      (expect runButton.attr "disabled").toBe undefined
