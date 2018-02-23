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

{ ExampleModel, ExampleModelState } = require "./model/example-model"
{ RangeSet } = require "./model/range-set"
{ File, SymbolSet } = require "./model/symbol-set"

$ = require "jquery"
log = require "examplify-log"


# This constant determines the name of the output example.
EXAMPLE_FILE_NAME = "ExtractedExample.java"


module.exports = plugin =

  subscriptions: null

  activate: (state) ->

    # Mark the current code editor as the source editor
    @codeEditor = atom.workspace.getActiveTextEditor()
    codeEditorView = atom.views.getView @codeEditor
    ($ codeEditorView).addClass 'source-editor'

    # Prepare user interface panels
    @pluginController = new MainController()
    atom.views.addViewProvider MainController, (controller) =>
      (new ControllerView controller).getNode()
    atom.workspace.addRightPanel { item: @pluginController }

    @subscriptions = new CompositeDisposable()
    @subscriptions.add (atom.commands.add "atom-workspace",
      "examplify:reset": =>
        thisPackage = atom.packages.getActivePackage "codescoop"
        thisPackage.onDidDeactivate =>
          # Force an immediate reload of the package.  Just the API `activate`
          # might defer activation for later.
          thisPackage.activateNow()
        thisPackage.deactivate()
      "examplify:make-example-code": =>

        # Don't allow any edits to the source code at this point
        ($ codeEditorView).addClass 'locked-editor'

        # Launch a new editor to hold the example code.
        (atom.workspace.open EXAMPLE_FILE_NAME, { split: "right" }).then \
          (exampleEditor) =>

            @exampleEditor = exampleEditor

            # Editor syntax should be for Java instead of default
            if atom.grammars.grammarsByScopeName['source.java']?
              exampleEditor.setGrammar atom.grammars.grammarsByScopeName['source.java']

            # Initialize the controller now that the scoop is starting
            @pluginController.init @codeEditor, @exampleEditor

            # Set the class, so we can do stylings that hide typical signifiers
            # of text modifiability, like cursors and highlights.
            exampleEditorView = atom.views.getView @exampleEditor
            ($ exampleEditorView).addClass 'example-editor'
            ($ exampleEditorView).addClass 'locked-editor'

            # This editor should be read-only.
            # Abort any textual changes so user can't type in code.
            exampleEditor.onWillInsertText (event) =>
              if @pluginController.getModel().getState() != ExampleModelState.IDLE
                event.cancel()
            ($ exampleEditorView).click (event) =>
              if @pluginController.getModel().getState() == ExampleModelState.IDLE
                ($ exampleEditorView).removeClass 'locked-editor'
              else if @pluginController.getModel().getState() == ExampleModelState.IDLE
                ($ exampleEditorView).addClass 'locked-editor'

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

    # Reset the user interface to where it was before.
    @exampleEditor.destroy() if @exampleEditor?
    for panel in atom.workspace.getRightPanels()
      panel.destroy() if panel.item instanceof MainController

    # Reset main data fields
    @pluginController = undefined

    # Open a new source program editor, without annotations and highlights.
    # Force the file-open action to be synchronous.
    sourcePath = @codeEditor.getPath()
    @codeEditor.destroy()
    (atom.workspace.open sourcePath).then()

  serialize: () ->
    return {}


module.exports.MainController = class MainController

  constructor: ->
    @initListeners = []

  init: (codeEditor, exampleEditor) ->

    @codeEditor = codeEditor
    @exampleEditor = exampleEditor

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

    # Prepare analyses
    codeEditorFile = new File codeEditor.getPath(), codeEditor.getTitle()
    @analyses =
      importAnalysis: new ImportAnalysis codeEditorFile
      variableDefUseAnalysis: new VariableDefUseAnalysis codeEditorFile
      catchVariableDefAnalysis: new CatchVariableDefAnalysis codeEditorFile, @parseTree, @exampleModel
      methodDefUseAnalysis: new MethodDefUseAnalysis codeEditorFile, @parseTree
      typeDefUseAnalysis: new TypeDefUseAnalysis codeEditorFile, @parseTree
      valueAnalysis: new ValueAnalysis codeEditorFile
      stubAnalysis: new StubAnalysis codeEditorFile
      declarationsAnalysis: new DeclarationsAnalysis @symbols, codeEditorFile, @parseTree
      rangeGroupsAnalysis: new RangeGroupsAnalysis @parseTree
      throwsAnalysis: new ThrowsAnalysis codeEditorFile
      catchAnalysis: new CatchAnalysis @exampleModel

    # Prepare controllers
    @exampleController = new ExampleController \
      @exampleModel, { analyses: @analyses }

    for listener in @initListeners
      listener.onPluginInitDone @

  addInitListener: (listener) ->
    @initListeners.push listener

  # These accessors are here to let us test the controller
  getRangeSet: ->
    @rangeSet

  getModel: ->
    @exampleModel
