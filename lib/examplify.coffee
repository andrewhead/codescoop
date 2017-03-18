{ CompositeDisposable } = require "atom"
{ CodeView } = require "./code-view"
{ ExampleView } = require "./example-view"
{ StubPreview } = require "./view/stub-preview"

{ ExampleModel } = require "./model/example-model"

{ ExampleController } = require "./example-controller"
{ DefUseAnalysis } = require "./analysis/def-use"
{ ValueAnalysis } = require "./analysis/value-analysis"
{ StubAnalysis } = require "./analysis/stubs"

{ RangeSet } = require "./model/range-set"
{ File, SymbolSet } = require "./model/symbol-set"
{ parse } = require "./analysis/parse-tree"
$ = require "jquery"


EXAMPLE_FILE_NAME = "SmallScoop.java"


module.exports = plugin =

  subscriptions: null
  # controller: null

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

    # Prepare views
    @codeView = new CodeView codeEditor, @rangeSet
    @exampleView = new ExampleView @exampleModel, exampleEditor
    @stubPreview = new StubPreview @exampleModel

    # Prepare analyses
    codeEditorFile = new File codeEditor.getPath(), codeEditor.getTitle()
    @analyses =
      defUseAnalysis: new DefUseAnalysis codeEditorFile
      valueAnalysis: new ValueAnalysis codeEditorFile
      stubAnalysis: new StubAnalysis codeEditorFile

    # Prepare controllers
    @exampleController = new ExampleController @exampleModel, @analyses

  # These accessors are here to let us test the controller
  getRangeSet: ->
    @rangeSet

  getModel: ->
    @exampleModel
