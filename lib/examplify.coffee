{ CompositeDisposable } = require "atom"
{ CodeView } = require "./view/code-view"
{ ExampleView } = require "./view/example-view"
{ StubPreview } = require "./view/stub-preview"
{ AgentRunnerView } = require "./view/agent-runner-view"

{ ExampleModel } = require "./model/example-model"

{ ExampleController } = require "./example-controller"
{ ImportAnalysis } = require "./analysis/import-analysis"
{ VariableDefUseAnalysis } = require "./analysis/variable-def-use"
{ TypeDefUseAnalysis } = require "./analysis/type-def-use"
{ ValueAnalysis } = require "./analysis/value-analysis"
{ StubAnalysis } = require "./analysis/stub-analysis"

{ AgentRunner } = require "./agent/agent-runner"

{ RangeSet } = require "./model/range-set"
{ File, SymbolSet } = require "./model/symbol-set"
{ parse } = require "./analysis/parse-tree"
$ = require "jquery"


EXAMPLE_FILE_NAME = "SmallScoop.java"


module.exports = plugin =

  subscriptions: null

  activate: (state) ->
    @subscriptions = new CompositeDisposable()
    @subscriptions.add (atom.commands.add "atom-workspace",
      "examplify:make-example-code": =>
        @codeEditor = atom.workspace.getActiveTextEditor()
        (atom.workspace.open EXAMPLE_FILE_NAME, { split: "right" }).then \
          (exampleEditor) =>
            @controller = new MainController @codeEditor, exampleEditor
      "examplify:add-selection-to-example": =>
        selectedRange = @codeEditor.getSelectedBufferRange()
        rangeSet = @controller.getModel().getRangeSet()
        rangeSet.getActiveRanges().push selectedRange
      "examplify:undo": =>
        @controller.exampleController.undo()
    )

  deactivate: () ->
    this.subscriptions.dispose()

  serialize: () ->
    return {}


module.exports.MainController = class MainController

  constructor: (codeEditor, exampleEditor) ->

    selectedRange = codeEditor.getSelectedBufferRange()
    activeRanges = [ selectedRange ]

    # Prepare models (data)
    @rangeSet = new RangeSet activeRanges
    @symbols = new SymbolSet()
    @parseTree = parse codeEditor.getText()
    @exampleModel = new ExampleModel codeEditor.getBuffer(), @rangeSet,\
      @symbols, @parseTree

    # Prepare agents
    @agentRunner = new AgentRunner @exampleModel

    # Prepare views (note that this involves removing *previous* views)
    @codeView = new CodeView codeEditor, @rangeSet
    @exampleView = new ExampleView @exampleModel, exampleEditor
    @stubPreview = new StubPreview @exampleModel
    for bottomPanel in atom.workspace.getBottomPanels()
      bottomPanel.destroy() if bottomPanel.item instanceof AgentRunner
    atom.views.addViewProvider AgentRunner, (agentRunner) =>
      (new AgentRunnerView @exampleModel, agentRunner).getNode()
    atom.workspace.addBottomPanel { item: @agentRunner }

    # Prepare analyses
    codeEditorFile = new File codeEditor.getPath(), codeEditor.getTitle()
    @analyses =
      importAnalysis: new ImportAnalysis codeEditorFile
      variableDefUseAnalysis: new VariableDefUseAnalysis codeEditorFile
      typeDefUseAnalysis: new TypeDefUseAnalysis codeEditorFile, @parseTree
      valueAnalysis: new ValueAnalysis codeEditorFile
      stubAnalysis: new StubAnalysis codeEditorFile

    # Prepare controllers
    @exampleController = new ExampleController \
      @exampleModel, { analyses: @analyses }

  # These accessors are here to let us test the controller
  getRangeSet: ->
    @rangeSet

  getModel: ->
    @exampleModel
