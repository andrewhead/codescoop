{ CompositeDisposable } = require "atom"
{ CodeView } = require "./view/code-view"
{ ExampleView } = require "./view/example-view"
{ StubPreview } = require "./view/stub-preview"
{ ControllerView } = require "./view/controller-view"

{ parse } = require "./analysis/parse-tree"
{ ExampleController } = require "./example-controller"
{ ImportAnalysis } = require "./analysis/import-analysis"
{ VariableDefUseAnalysis } = require "./analysis/variable-def-use"
{ CatchVariableDefAnalysis } = require "./analysis/catch-variable-def"
{ MethodDefUseAnalysis } = require "./analysis/method-def-use"
{ TypeDefUseAnalysis } = require "./analysis/type-def-use"
{ ValueAnalysis } = require "./analysis/value-analysis"
{ StubAnalysis } = require "./analysis/stub-analysis"
{ DeclarationsAnalysis } = require "./analysis/declarations"
{ RangeGroupsAnalysis } = require "./analysis/range-groups"
{ ThrowsAnalysis } = require "./analysis/throws-analysis"
{ CatchAnalysis } = require "./analysis/catch"

{ ExampleModel } = require "./model/example-model"
{ RangeSet } = require "./model/range-set"
{ File, SymbolSet } = require "./model/symbol-set"

$ = require "jquery"
log = require "examplify-log"


# This constant determines the name of the output example.
EXAMPLE_FILE_NAME = "ExtractedExample.java"


module.exports = plugin =

  subscriptions: null

  activate: (state) ->

    @subscriptions = new CompositeDisposable()
    @subscriptions.add (atom.commands.add "atom-workspace",
      "examplify:make-example-code": =>

        # Mark the current code editor as the source editor
        @codeEditor = atom.workspace.getActiveTextEditor()
        codeEditorView = atom.views.getView @codeEditor
        ($ codeEditorView).addClass 'source-editor'

        # Launch a new editor to hold the example code.
        (atom.workspace.open EXAMPLE_FILE_NAME, { split: "right" }).then \
          (exampleEditor) =>
            # This editor should be read-only.
            # Abort any textual changes so user can't type in code.
            exampleEditor.onWillInsertText (event) => event.cancel()
            exampleEditorView = atom.views.getView exampleEditor
            # Set the class, so we can do stylings that hide typical signifiers
            # of text modifiability, like cursors and highlights.
            ($ exampleEditorView).addClass 'example-editor'
            @controller = new MainController @codeEditor, exampleEditor

      "examplify:add-selection-to-example": =>
        selectedRange = @codeEditor.getSelectedBufferRange()
        rangeSet = @controller.getModel().getRangeSet()
        rangeSet.getChosenRanges().push selectedRange
      "examplify:undo": =>
        log.debug "Key press for undo"
        @controller.exampleController.undo()
    )

  deactivate: () ->
    this.subscriptions.dispose()

  serialize: () ->
    return {}


module.exports.MainController = class MainController

  constructor: (codeEditor, exampleEditor) ->

    selectedRanges = codeEditor.getSelectedBufferRanges()
    snippetRanges = selectedRanges

    # Prepare models (data)
    @rangeSet = new RangeSet snippetRanges
    @symbols = new SymbolSet()
    @parseTree = parse codeEditor.getText()
    @exampleModel = new ExampleModel codeEditor.getBuffer(), @rangeSet,\
      @symbols, @parseTree

    # Prepare agents
    @codeView = new CodeView codeEditor, @rangeSet
    @exampleView = new ExampleView @exampleModel, exampleEditor
    @stubPreview = new StubPreview @exampleModel

    # Prepare user interface panels
    for panel in atom.workspace.getRightPanels()
      panel.destroy() if panel.item instanceof ExampleController
    atom.views.addViewProvider ExampleController, (controller) =>
      (new ControllerView controller, @exampleModel, exampleEditor).getNode()

    # Prepare analyses
    codeEditorFile = new File codeEditor.getPath(), codeEditor.getTitle()
    @analyses =
      importAnalysis: new ImportAnalysis codeEditorFile
      variableDefUseAnalysis: new VariableDefUseAnalysis codeEditorFile
      catchVariableDefAnalysis: new CatchVariableDefAnalysis codeEditorFile, @parseTree, @exampleModel
      methodDefUseAnalysis: new MethodDefUseAnalysis codeEditorFile, @parseTree
      typeDefUseAnalysis: new TypeDefUseAnalysis codeEditorFile, @parseTree
      valueAnalysis: new ValueAnalysis codeEditorFile
      # stubAnalysis: new StubAnalysis codeEditorFile
      declarationsAnalysis: new DeclarationsAnalysis @symbols, codeEditorFile, @parseTree
      rangeGroupsAnalysis: new RangeGroupsAnalysis @parseTree
      throwsAnalysis: new ThrowsAnalysis codeEditorFile
      catchAnalysis: new CatchAnalysis @exampleModel

    # Prepare controllers
    @exampleController = new ExampleController \
      @exampleModel, { analyses: @analyses }

    atom.workspace.addRightPanel { item: @exampleController }

  # These accessors are here to let us test the controller
  getRangeSet: ->
    @rangeSet

  getModel: ->
    @exampleModel
