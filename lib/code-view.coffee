{ Range, RangeSetProperty } = require './model/range-set'
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
    @listenForRefocus()
    @update()

  getEditor: ->
    @editor

  onPropertyChanged: (object, propertyName, propertyValue) ->
    @update() if (
      propertyName is RangeSetProperty.ACTIVE_RANGES_CHANGED or
      propertyName is RangeSetProperty.SUGGESTED_RANGES_CHANGED
    )

  update: ->

    editorView = atom.views.getView @textEditor
    lines = $ ( editorView.querySelectorAll 'div.line' )

    _rangesToRows = (ranges) =>
      rows = []
      for range in ranges
        for rowNumber in range.getRows()
          if rowNumber not in rows
            rows.push rowNumber
      rows

    activeRows = _rangesToRows @rangeSet.getActiveRanges()
    suggestedRows = _rangesToRows @rangeSet.getSuggestedRanges()

    # By default, no lines are chosen or unchosen
    ((lines.removeClass 'inactive').removeClass 'active').removeClass 'suggested'
    for line in ($ _ for _ in lines)

      # We access "screenRow" through dataset and not the jQuery data() function
      # because it looks like Atom recycles lines, and when it does, it updates
      # the screenRow property, but jQuery.data('screenRow') somehow maintains
      # the value of the recycled line before reuse.
      # Note: the code must be completely unfolded for highlighting based on
      # the 'screen-row' data property to work
      screenRowNumber = Number(line[0].dataset.screenRow)
      line.addClass (
        if (screenRowNumber in activeRows)\
        then 'active' else 'inactive'
        )
      line.addClass 'suggested' if screenRowNumber in suggestedRows

  listenForRefocus: ->

    # Whenever the DOM is changed, we need to make sure that lines are
    # highlighted and dimmed.  However, with Atom, line `div`s change whenever
    # they scroll on or off-screen, or when their content changes.  This ruins
    # the highlighting effect we're working with.  So, we listen to when
    # the DOM contents change, and when the active editor changes, and
    # update the highlighting and dimming.
    editorView = atom.views.getView @textEditor
    scrollObserver = new MutationObserver ((m, o) => @update())
    scrollObserver.observe editorView, { childList: true, subtree: true }
