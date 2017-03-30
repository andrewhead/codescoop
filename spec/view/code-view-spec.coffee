{ CodeView } = require "../../lib/view/code-view"
{ Range, RangeSet } = require "../../lib/model/range-set"
$ = require "jquery"


describe "CodeView", () ->

  _makeEditor = ->
    editor = atom.workspace.buildTextEditor()
    editor.setText [
      "Line 1"
      "Line 2"
      "Line 3"
      "Line 4"
      ].join "\n"
    editor

  _addLines = (editorView) ->
    ($ (editorView.querySelector "div.lines")).append $(
      $("<div class=line data-screen-row=0>Line 1</div>" +
        "<div class=line data-screen-row=1>Line 2</div>" +
        "<div class=line data-screen-row=2>Line 3</div>" +
        "<div class=line data-screen-row=3>Line 4</div>"
      )
    )

  it "highlights the chosen lines and dims the rest", ->

    rangeSet = new RangeSet [ new Range [1, 0], [1, 5] ]
    editor = _makeEditor()
    codeView = new CodeView editor, rangeSet

    # It looks like headless editors don"t ge populated with buffer rows.
    # So let"s go ahead and make the buffer rows we expect to appear
    editorView = atom.views.getView(editor)
    _addLines(editorView)

    # Once we update highlighting, the second line should be marked as
    # "chosen" and the other lines as "unchosen"
    codeView.updateHighlights()
    chosen = $ (editorView.querySelectorAll "div.lines .active")
    expect(chosen.length).toBe 1
    expect(chosen.data "screenRow").toBe 1
    expect(($ (editorView.querySelectorAll "div.lines .inactive")).length).toBe(3)

  it "updates highlighting when the chosen lines are modified", ->

    rangeSet = new RangeSet []
    editor = _makeEditor()
    codeView = new CodeView editor, rangeSet
    editorView = atom.views.getView(editor)
    _addLines(editorView)

    # Initially, the number of active lines in the DOM should be zero.
    # Though once we add an extra line to the set of active lines in the model
    # the view should update the DOM automatically
    codeView.updateHighlights()
    expect(($ (editorView.querySelectorAll "div.lines .active")).length).toBe 0
    rangeSet.getSnippetRanges().push new Range [1, 0], [1, 5]
    expect(($ (editorView.querySelectorAll "div.lines .active")).length).toBe 1

  it "adds an extra highlight to suggested lines", ->

    rangeSet = new RangeSet [], [ new Range [1, 0], [1, 5] ]
    editor = _makeEditor()
    codeView = new CodeView editor, rangeSet
    editorView = atom.views.getView(editor)
    _addLines(editorView)

    # Initially, the number of active lines in the DOM should be zero.
    # Though once we add an extra line to the set of active lines in the model
    # the view should update the DOM automatically
    codeView.updateHighlights()
    expect(($ (editorView.querySelectorAll "div.lines .suggested")).length).toBe 1
    expect(($ (editorView.querySelectorAll "div.lines div.line:not(.suggested)")).length).toBe 3

  it "updates suggested line highlighting when suggested lines change", ->

    rangeSet = new RangeSet [], []
    editor = _makeEditor()
    codeView = new CodeView editor, rangeSet
    editorView = atom.views.getView(editor)
    _addLines(editorView)

    # Initially, the number of active lines in the DOM should be zero.
    # Though once we add an extra line to the set of active lines in the model
    # the view should update the DOM automatically
    codeView.updateHighlights()
    expect(($ (editorView.querySelectorAll "div.lines .suggested")).length).toBe 0
    rangeSet.getSuggestedRanges().push new Range [0, 0], [0, 5]
    expect(($ (editorView.querySelectorAll "div.lines .suggested")).length).toBe 1

  it "removes suggested line highlighting when suggested line removed", ->

    suggestedRange = new Range [1, 0], [1, 5]
    rangeSet = new RangeSet [], [ suggestedRange ]
    editor = _makeEditor()
    codeView = new CodeView editor, rangeSet
    editorView = atom.views.getView(editor)
    _addLines(editorView)

    codeView.updateHighlights()
    expect(($ (editorView.querySelectorAll "div.lines .suggested")).length).toBe 1
    rangeSet.getSuggestedRanges().remove suggestedRange
    expect(($ (editorView.querySelectorAll "div.lines .suggested")).length).toBe 0

  it "scrolls to a suggested range when a suggested range added", ->

    rangeSet = new RangeSet [], []
    editor = _makeEditor()
    (spyOn editor, "scrollToBufferPosition").andCallThrough()
    codeView = new CodeView editor, rangeSet

    rangeSet.getSuggestedRanges().push new Range [1, 0], [1, 5]
    (expect editor.scrollToBufferPosition).toHaveBeenCalledWith [1, 0]
