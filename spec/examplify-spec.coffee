{ Range } = require '../lib/model/range-set'
{ MainController } = require '../lib/examplify'
{ PACKAGE_PATH } = require '../lib/config/paths'
{ AgentRunner } = require "../lib/agent/agent-runner"
$ = require 'jquery'


_makeCodeEditor = =>
  codeEditor = atom.workspace.buildTextEditor()
  codeEditor.setText [
    "Line 1"
    "Line 2"
    "Line 3"
    "Line 4"
    ].join '\n'
  codeEditor


describe "The Examplify Plugin", ->

  TEST_FILENAME = PACKAGE_PATH + "/java/tests/analysis_examples/Example.java"
  workspaceElement = undefined
  activationPromise = undefined
  examplifyPackage = undefined

  # Based on boilerplate test spec code by GitHub Atom
  beforeEach =>

    workspaceElement = (atom.views.getView atom.workspace)
    activationPromise = atom.packages.activatePackage 'examplify'

    # Open up our example file
    waitsForPromise =>
      atom.workspace.open TEST_FILENAME

  it "adds lines to the active set when the context menu is clicked", ->

    # Note: it seems like activation needs to be ordered is:
    # 1. Make activation promise above
    # 2. Dispatch a command that will do activation
    # 3. `waitForPromise` on the activation
    # 4. `runs` the rest of the code

    # Make a selection, and start creating example code!
    editor = atom.workspace.getActiveTextEditor()
    editor.setSelectedBufferRange new Range [5, 0], [5, 43]
    atom.commands.dispatch workspaceElement, "examplify:make-example-code"

    waitsForPromise =>
      activationPromise

    # After activating the package, we want to wait until the controller
    # is initialized, so we can add another selection
    runs =>
      examplifyPackage = atom.packages.getActivePackage 'examplify'
    waitsFor =>
      examplifyPackage.mainModule.controller

    runs =>

      # Initially, there should only be one selection in the active set...
      controller = examplifyPackage.mainModule.controller
      (expect controller.getModel().getRangeSet().getSnippetRanges().length).toBe 1

      # After we make another selection, it should get added to the active set
      editor.setSelectedBufferRange new Range [4, 0], [4, 35]
      atom.commands.dispatch workspaceElement, "examplify:add-selection-to-example"
      (expect controller.getModel().getRangeSet().getSnippetRanges().length).toBe 2

  it "calls \"undo\" to the controller when \"undo\" command is run", ->

    editor = atom.workspace.getActiveTextEditor()
    editor.setSelectedBufferRange new Range [5, 0], [5, 43]
    atom.commands.dispatch workspaceElement, "examplify:make-example-code"
    waitsForPromise =>
      activationPromise

    # Wait for the controller to be initialized
    runs =>
      examplifyPackage = atom.packages.getActivePackage 'examplify'
    waitsFor =>
      examplifyPackage.mainModule.controller

    runs =>
      exampleController = examplifyPackage.mainModule.controller.exampleController
      (spyOn exampleController, "undo")
      atom.commands.dispatch workspaceElement, "examplify:undo"
      (expect exampleController.undo).toHaveBeenCalled()


describe "MainController", ->

  it "updates the line set to the selected lines when invoked", ->

    codeEditor = _makeCodeEditor()
    exampleEditor = atom.workspace.buildTextEditor()

    # There's one weird part of test setup: as these text editors aren't
    # based on panes from the environment, we need to supply title and path
    (spyOn codeEditor, 'getTitle').andReturn "BogusTitle.java"
    (spyOn codeEditor, 'getPath').andReturn "/tmp/bogus/path/BogusTitle.java"

    # Remember that while the range specifies line 1, this actually corresponds
    # to line 2 as it appears in the text editor
    selectedRange = new Range [1, 0], [1, 2]
    codeEditor.clearSelections()
    selection = codeEditor.setSelectedBufferRange selectedRange

    mainController = new MainController codeEditor, exampleEditor
    (expect mainController.getRangeSet().getSnippetRanges()).toEqual \
      [ new Range [1, 0], [1, 2] ]

  it 'highlights lines on the screen when invoked with a selection', ->

    codeEditor = _makeCodeEditor()
    exampleEditor = atom.workspace.buildTextEditor()
    (spyOn codeEditor, 'getTitle').andReturn "BogusTitle.java"
    (spyOn codeEditor, 'getPath').andReturn "/tmp/bogus/path/BogusTitle.java"

    # Add some lines to the code editor that can be selected
    codeEditorView = atom.views.getView(codeEditor)
    ($ (codeEditorView.querySelector "div.scroll-view div:first-child")).append $(
      "<div class=lines>" +
          "<div class=line data-screen-row=0>Line 1</div>" +
          "<div class=line data-screen-row=1>Line 2</div>" +
          "<div class=line data-screen-row=2>Line 3</div>" +
          "<div class=line data-screen-row=3>Line 4</div>" +
        "</div>"
    )

    selectedRange = new Range [1, 0], [1, 2]
    selection = codeEditor.setSelectedBufferRange selectedRange
    mainController = new MainController codeEditor, exampleEditor

    # Check to see that one of the lines was activated based on selectedRange
    activeLines = ($ (codeEditorView.querySelectorAll 'div.line.active'))
    (expect activeLines.length).toBe 1
