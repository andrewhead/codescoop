{ Range, RangeSetProperty } = require './range-set'
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
    @update()

  getEditor: ->
    @editor

  _screenRowToLineNumber: (screenRow) ->
    # We assume that the code is completely unfolded.
    screenRow

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
      screenRowNumber = @_screenRowToLineNumber (line.data 'screenRow')
      line.addClass (
        if (screenRowNumber in activeRows)\
        then 'active' else 'inactive'
        )
      line.addClass 'suggested' if screenRowNumber in suggestedRows
