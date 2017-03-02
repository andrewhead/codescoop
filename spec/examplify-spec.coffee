{ Range } = require 'atom'
{ MainController } = require '../lib/examplify'
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


describe 'MainController', () ->

  it 'updates the line set to the selected lines when invoked', ->

    codeEditor = _makeCodeEditor()
    exampleEditor = atom.workspace.buildTextEditor()

    # There's one weird part of test setup: as these text editors aren't
    # based on panes from the environment, we need to supply title and path
    (spyOn codeEditor, 'getTitle').andReturn "BogusTitle.java"
    (spyOn codeEditor, 'getPath').andReturn "/tmp/bogus/path/BogusTitle.java"

    # Remember that while the range specifies line 1, this actually corresponds
    # to line 2 as it appears in the text editor
    selectedRange = new Range [1, 0], [1, 2]
    selection = codeEditor.addSelectionForBufferRange selectedRange

    mainController = new MainController codeEditor, exampleEditor
    (expect mainController.getLineSet().getActiveLineNumbers()).toEqual [2]

  it 'highlights lines on the screen when invoked with a selection', ->

    codeEditor = _makeCodeEditor()
    exampleEditor = atom.workspace.buildTextEditor()
    (spyOn codeEditor, 'getTitle').andReturn "BogusTitle.java"
    (spyOn codeEditor, 'getPath').andReturn "/tmp/bogus/path/BogusTitle.java"

    # Add some lines to the code editor that can be selected
    codeEditorView = atom.views.getView(codeEditor)
    ($ (codeEditorView.querySelector 'div.lines')).append $(
      $("<div class=line data-screen-row=0>Line 1</div>" +
        "<div class=line data-screen-row=1>Line 2</div>" +
        "<div class=line data-screen-row=2>Line 3</div>" +
        "<div class=line data-screen-row=3>Line 4</div>"
      )
    )

    selectedRange = new Range [1, 0], [1, 2]
    selection = codeEditor.addSelectionForBufferRange selectedRange
    mainController = new MainController codeEditor, exampleEditor

    # Check to see that one of the lines was activated based on selectedRange
    activeLines = ($ (codeEditorView.querySelectorAll 'div.line.active'))
    (expect activeLines.length).toBe 1
