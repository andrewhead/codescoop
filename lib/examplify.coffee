{ CompositeDisposable } = require "atom"
{ CodeView } = require "./view/code-view"
{ ExampleView } = require "./view/example-view"
{ StubPreview } = require "./view/stub-preview"
{ ControllerView } = require "./view/controller-view"
{ HelpView } = require "./view/help-view"

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

{ ExampleModel, ExampleModelProperty, ExampleModelState } = require "./model/example-model"
{ RangeSet, Range } = require "./model/range-set"
{ File, SymbolSet } = require "./model/symbol-set"

$ = require "jquery"
log = require "examplify-log"


# This constant determines the name of the output example.
EXAMPLE_FILE_NAME = "ExtractedExample.java"


disableKeystrokes = (editorView, shouldDisable) =>
  ($ editorView).on 'keydown', (e) =>
    code = e.keyCode or e.which
    # Still allow arrow keys and shortcuts
    if not (e.ctrlKey or e.metaKey or e.altKey or (code <= 40 and code >= 37))
      if (not shouldDisable?)
        e.preventDefault()
        e.stopPropagation()
        return
      if shouldDisable()
        e.preventDefault()
        e.stopPropagation()
        return


module.exports = plugin =

  subscriptions: null

  activate: (state) ->

    # Mark the current code editor as the source editor
    @codeEditor = atom.workspace.getActiveTextEditor()
    codeEditorView = atom.views.getView @codeEditor
    ($ codeEditorView).addClass 'source-editor'
    disableKeystrokes codeEditorView

    # Prepare user interface panels
    @pluginController = new MainController()
    atom.views.addViewProvider MainController, (controller) =>
      (new ControllerView controller).getNode()
    atom.workspace.addRightPanel { item: new HelpView() }
    atom.workspace.addRightPanel { item: @pluginController }

    @subscriptions = new CompositeDisposable()
    @subscriptions.add (atom.commands.add "atom-workspace",
      "examplify:reset": =>
        @deactivate(=> @activate())
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
            ($ exampleEditorView).addClass 'loading'
            ($ exampleEditorView)
              .append("<div class='loading_container'><div class='loading_indicator'></div></div>")

            # This editor should be read-only.
            # Abort any textual changes so user can't type in code.
            disableKeystrokes exampleEditorView, =>
              @pluginController.getModel().getState() != ExampleModelState.IDLE
            # exampleEditor.onWillInsertText (event) =>
            #   if @pluginController.getModel().getState() != ExampleModelState.IDLE
            #     event.cancel()
            ($ exampleEditorView).click (event) =>
              if @pluginController.getModel().getState() == ExampleModelState.IDLE
                ($ exampleEditorView).removeClass 'locked-editor'
              else if @pluginController.getModel().getState() == ExampleModelState.IDLE
                ($ exampleEditorView).addClass 'locked-editor'

      # examplify:add-selection-to-example": =>
      #   selectedRange = @codeEditor.getSelectedBufferRange()
      #   rangeSet = @controller.getModel().getRangeSet()
      #   rangeSet.getChosenRanges().push selectedRange
      "examplify:undo": =>
        log.debug "Key press for undo"
        @controller.exampleController.undo()
    )

  deactivate: (onDidDeactivate) ->
    this.subscriptions.dispose()

    # Reset the user interface to where it was before.
    @exampleEditor.destroy() if @exampleEditor?
    while atom.workspace.getRightPanels().length >= 1
      atom.workspace.getRightPanels()[0].destroy()

    # Reset the source program editor
    codeEditorView = atom.views.getView @codeEditor
    ($ codeEditorView).removeClass 'locked-editor'
    @pluginController.codeView.destroy()

    # Reset main data fields
    @pluginController = undefined

    # Callback for after deactivation
    onDidDeactivate() if onDidDeactivate?

  serialize: () ->
    return {}


module.exports.MainController = class MainController

  constructor: ->
    @initListeners = []

  init: (codeEditor, exampleEditor) ->

    @codeEditor = codeEditor
    @exampleEditor = exampleEditor

    selectedRanges = codeEditor.getSelectedBufferRanges()
    buffer = codeEditor.getBuffer()

    # Include full lines for every line where more than just
    # whitespace was selected.
    snippetRanges = []
    for range in selectedRanges
      for rowNumber in [range.start.row..range.end.row]

        lineFullRange = buffer.rangeForRow rowNumber
        if rowNumber is range.start.row
          lineRange = new Range range.start, lineFullRange.end
        else if rowNumber is range.end.row
          lineRange = new Range lineFullRange.start, range.end
        else
          lineRange = lineFullRange

        if not /^\s*$/.test buffer.getTextInRange lineRange
          snippetRanges.push lineFullRange

    # Prepare models (data)
    @rangeSet = new RangeSet []
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

    @exampleModel.addObserver {
      exampleEditor: @exampleEditor
      waitingToAddRanges: true
      onPropertyChanged: (model, propertyName, oldValue, newValue) ->
        if @waitingToAddRanges
          if propertyName is ExampleModelProperty.STATE
            if newValue is ExampleModelState.IDLE
              @waitingToAddRanges = false
              for range in snippetRanges
                model.getRangeSet().getChosenRanges().push range
              exampleEditorView = atom.views.getView @exampleEditor
              ($ exampleEditorView).removeClass "loading"
    }

    for listener in @initListeners
      listener.onPluginInitDone @

  addInitListener: (listener) ->
    @initListeners.push listener

  # These accessors are here to let us test the controller
  getRangeSet: ->
    @rangeSet

  getModel: ->
    @exampleModel
