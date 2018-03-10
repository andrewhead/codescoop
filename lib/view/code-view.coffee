{ Range, RangeSetProperty } = require '../model/range-set'
log = require 'examplify-log'
$ = require 'jquery'

CodeViewerState =
  EDITING: 1  # Highlighting inactive
  EXAMPLIFYING: 2  # Still making an example, highlighting active
  SHOW_UNDEFINED: 3
  SHOW_DEFINITIONS: 4


module.exports.CodeView = class CodeView

  constructor: (textEditor, rangeSet) ->
    @textEditor = textEditor
    @rangeSet = rangeSet
    @rangeSet.addObserver @
    @listenForLineClick()
    @listenForRefocus()
    @updateHighlights()

  getEditor: ->
    @editor

  onPropertyChanged: (object, propertyName, oldValue, newValue) ->
    @updateHighlights() if (
      propertyName is RangeSetProperty.ACTIVE_RANGES_CHANGED or
      propertyName is RangeSetProperty.SUGGESTED_RANGES_CHANGED
    )
    @scrollToSuggestedRange() if (
      (propertyName is RangeSetProperty.SUGGESTED_RANGES_CHANGED) and
      (newValue.length > oldValue.length)
    )

  updateHighlights: ->

    # By default, no lines are chosen or unchosen
    @resetHighlights()

    _rangesToRows = (ranges) =>
      rows = []
      for range in ranges
        for rowNumber in range.getRows()
          if rowNumber not in rows
            rows.push rowNumber
      rows

    activeRows = _rangesToRows @rangeSet.getActiveRanges()
    suggestedRows = _rangesToRows @rangeSet.getSuggestedRanges()

    editorView = atom.views.getView @textEditor
    lines = $ ( editorView.querySelectorAll 'div.line' )
    for line in ($ _ for _ in lines)

      # We access "screenRow" through dataset and not the jQuery data() function
      # because it looks like Atom recycles lines, and when it does, it updates
      # the screenRow property, but jQuery.data('screenRow') somehow maintains
      # the value of the recycled line before reuse.
      # Note: the code must be completely unfolded for highlighting based on
      # the 'screen-row' data property to work
      screenRowNumber = Number(line[0].dataset.screenRow)
      line.addClass (
        # XXX: sometimes when the cursor is moved to a line, it overwrites the
        # class assignments that we set here.
        if (screenRowNumber in activeRows)\
        then 'active' else 'inactive'
        )
      line.addClass 'suggested' if screenRowNumber in suggestedRows

  scrollToSuggestedRange: ->
    # I couldn't find any members of the Atom API that would let me query
    # for the current scroll position of the text editor.  So for now, we
    # somewhat lazily just scroll to the first available suggested range.
    suggestedRange = @rangeSet.getSuggestedRanges()[0]
    @textEditor.scrollToBufferPosition \
      [suggestedRange.start.row, suggestedRange.start.column]

  listenForLineClick: ->
    editorView = (atom.views.getView @textEditor)
    (($ editorView).find '.gutter').on 'mousedown mouseover', '.line-number', (event) =>
      if event.which in [undefined, 1]
        rowNumber = Number(event.target.dataset.screenRow)
        # log.debug "Clicked on line number", { lineNumber: rowNumber }
        lineLength = (@textEditor.lineTextForScreenRow rowNumber).length
        newRange = new Range [rowNumber, 0], [rowNumber, lineLength]
        if newRange not in @rangeSet.getChosenRanges()
          @rangeSet.getChosenRanges().push newRange

  listenForRefocus: ->

    # Whenever the DOM is changed, we need to make sure that lines are
    # highlighted and dimmed.  However, with Atom, line `div`s change whenever
    # they scroll on or off-screen, or when their content changes.  This ruins
    # the highlighting effect we're working with.  So, we listen to when
    # the DOM contents change, and when the active editor changes, and
    # update the highlighting and dimming.
    editorView = atom.views.getView @textEditor
    @scrollObserver = new MutationObserver ((m, o) => @updateHighlights())
    @scrollObserver.observe editorView, { childList: true, subtree: true }

  resetHighlights: ->
    editorView = atom.views.getView @textEditor
    lines = $ ( editorView.querySelectorAll 'div.line' )
    ((lines.removeClass 'inactive').removeClass 'active').removeClass 'suggested'

  destroy: ->
    editorView = atom.views.getView @textEditor
    @resetHighlights()
    @rangeSet.removeObserver @
    @scrollObserver.disconnect()
    (($ editorView).find '.gutter').off 'mousedown mouseover', '.line-number'
