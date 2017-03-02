{ Range } = require 'atom'
{ LineSetProperty } = require './line-set'
$ = require 'jquery'

CodeViewerState =
  EDITING: 1  # Highlighting inactive
  EXAMPLIFYING: 2  # Still making an example, highlighting active
  SHOW_UNDEFINED: 3
  SHOW_DEFINITIONS: 4


module.exports.CodeView = class CodeView

  constructor: (textEditor, lineSet) ->
    @textEditor = textEditor
    @lineSet = lineSet
    @lineSet.addObserver @
    @update()

  getEditor: ->
    @editor

  _screenRowToLineNumber: (screenRow) ->
    # We assume that the code is completely unfolded.  When this is true
    # the 'screen row' of a line is one less than the line number as it
    # appears in the text editor.
    screenRow + 1

  onPropertyChanged: (object, propertyName, propertyValue) ->
    @update() if (
      propertyName is LineSetProperty.ACTIVE_LINE_NUMBERS_CHANGED or
      propertyName is LineSetProperty.SUGGESTED_LINE_NUMBERS_CHANGED
    )

  update: ->

    editorView = atom.views.getView(@textEditor)
    lines = $ ( editorView.querySelectorAll 'div.line' )

    # By default, no lines are chosen or unchosen
    ((lines.removeClass 'inactive').removeClass 'active').removeClass 'suggested'
    for line in ($ _ for _ in lines)
      lineNumber = @_screenRowToLineNumber (line.data 'screenRow')
      line.addClass (
        if (lineNumber in @lineSet.getActiveLineNumbers())\
        then 'active' else 'inactive'
        )
      line.addClass 'suggested' if lineNumber in @lineSet.getSuggestedLineNumbers()

  """
  chosenLines: []
  state: CodeViewerState.EXAMPLIFYING
  definitionMarkers: []

  useSelectedListeners: []
  useDefinedListeners: []
  definitionAbandonedListeners: []

  constructor: (workspace, textEditor) ->

    @textEditor = textEditor

    # Update highlighting whenever the DOM changes
    @listenForRefocus()

    # XXX: Unfold all folds in editors to make sure our highlighting tricks
    # align to the right line indexes in the DOM.
    @textEditor.unfoldAll()

    # Listen to escape button to change state
    workspaceView = atom.views.getView atom.workspace
    workspaceView.addEventListener 'keyup', @onEscapeKeyUp.bind(@)

  highlightUndefinedUses: (undefinedUses) ->

    editor = @getTextEditor()

    for use in undefinedUses

      # Skip all temporary variables
      # XXX: Problematically, this leaves out all imported classes.
      if use.name.startsWith "$" then return

      marker = @_markSymbol(use)

      # Save all of the metadata so we can find this use symbol
      # when we query the dataflow analysis again
      definitionButton = $ '<div>Click to define.</div>'
      definitionButton.data 'symbol', use
      definitionButton.data 'marker', marker
      definitionButton.click (event) =>
        symbol = $(event.target).data 'symbol'
        thisButtonMarker = $(event.target).data 'marker'
        @clearDefinitionMarkers()
        @notifyUseSelectedListeners(use)

      # The first marker is a clickable button for repair
      editor.decorateMarker marker, {
        type: 'overlay',
        item: definitionButton,
        position: 'tail',
        class: 'definition-overlay'
      }

      # The second one just introduces some error colors
      editor.decorateMarker marker, {
        type: 'highlight',
        class: 'undefined-use'
      }

    @state = CodeViewerState.SHOW_UNDEFINED

  _onDefinitionComplete: (use) ->
    @clearDefinitionMarkers()
    @notifyUseDefinedListeners(use)
    @state = CodeViewerState.EXAMPLIFYING

  highlightDefinitions: (use, def, value) ->

    @state = CodeViewerState.SHOW_DEFINITIONS

    editor = @getTextEditor()

    # Create mark for the nearest definition of the symbol
    defMarker = @_markSymbol(def)

    # This is the container of different options of ways to define code
    defWidget = $ "<div></div>"
    insertButton = $ "<div class=definition-option>Insert Data</div>"
    defWidget.append insertButton

    # As the editor will be toggling between symbol and data, save the
    # original symbol name so we can revert to it
    useMarker = @_markSymbol use
    symbolName = editor.getTextInBufferRange useMarker.getBufferRange()

    # Only give user the option of inserting the value if a value was found
    # at some point in the runtime data.
    if value?
      insertButton\
        .mouseover (event) =>
          editor.setTextInBufferRange useMarker.getBufferRange(), value
        .mouseout (event) =>
          editor.setTextInBufferRange useMarker.getBufferRange(), symbolName
        .click (event) =>
          @_onDefinitionComplete(use)

        # TODO: Make another listener for this
        # It's important to re-run analysis because there are no longer the
        # same dependencies in the same locations when replacements were made.
        # XXX: currently we save the file to make sure analysis is run on
        # updated code.  In the future, it's better to make a temporary one.
        # editor.save()
        # plugin.analyze()
    else
      insertButton.addClass "disabled"

    # This button lets one preview what lines of code need to be added
    defButton = $ "<div class=definition-option>Add Definition</div>"
    defWidget.append defButton
    defButton\
      .mouseover (event) =>
        decoration = editor.decorateMarker defMarker, {
          type: 'line',
          class: 'definition'
        }
        ($ event.target).data 'decoration', decoration
      .mouseout (event) =>
        decoration = ($ event.target).data 'decoration'
        decoration.destroy() if decoration?
      .click (event) =>
        @chosenLines.push (def.line - 1)
        @_onDefinitionComplete(use)

    # The first marker is a clickable button for repair
    useMarker = @_markSymbol(use)
    editor.decorateMarker useMarker, {
      type: 'overlay',
      item: defWidget,
      position: 'tail',
      class: 'pick-overlay'
    }

  listenForRefocus: () ->

    # XXX: Whenever the DOM is changed, we need to make sure that lines are
    # highlighted in the same way.  The line `div`s change whenever they
    # scroll on or off-screen, or when their content changes.  This ruins
    # the highlighting effect we're working with.
    scrollObserver = new MutationObserver (mutations, observer) =>
      @repaint()

    scrollObserver.observe(
      document.querySelector('atom-pane-container.panes'),
      { childList: true, subtree: true }
      )

    # XXX: And whenever we switch editors (which apparently we can only)
    # detect by watching the DOM) update the highlighting rules
    editorChangeObserver = new MutationObserver (mutations, observer) =>
      @repaint()

    editorChangeObserver.observe(
      document.querySelector('atom-pane.pane.active'),
      { attributes: true }
      )

  ###
  View
  ###
  clearDefinitionMarkers: (exclude) ->
    for marker in @definitionMarkers
      if (not exclude?) or (exclude.indexOf(marker) is -1)
        marker.destroy()

  _getSymbolRange: (symbol) ->
    new Range [symbol.line - 1, symbol.start], [symbol.line - 1, symbol.end]

  _markSymbol: (symbol) ->
    editor = @getTextEditor()
    range = @_getSymbolRange symbol
    marker = editor.markBufferRange range, { invalidate: 'never' }
    @definitionMarkers.push marker
    marker

  repaint: ->

    # All lines should be reset to being non-highlighted.
    $('div.line').removeClass('chosen').removeClass 'unchosen';

    # If we're in normal editing mode, don't do any highlighting
    if @state is CodeViewerState.EDITING then return

    # XXX: Another HTML hack: find the lines on the page that correspond
    # to the main editor, and highlight those lines.
    if (@textEditor isnt undefined)
      codeLines = $(
        'atom-pane[data-active-item-name="' + @textEditor.getTitle() + '"] ' +
        'div.line')

      codeLines.each (i, line) =>
        lineIndex = Number $(line).data 'screenRow'
        if (@chosenLines.indexOf(lineIndex) isnt -1)
          $(line).addClass 'chosen'
        else
          $(line).addClass 'unchosen'

  ###
  Listeners
  ###
  addUseSelectedListener: (listener) ->
    @useSelectedListeners.push listener

  notifyUseSelectedListeners: (selected) ->
    for listener in @useSelectedListeners
      listener.onUseSelected selected

  addUseDefinedListener: (listener) ->
    @useDefinedListeners.push listener

  notifyUseDefinedListeners: (use) ->
    for listener in @useDefinedListeners
      listener.onUseDefined use

  addDefinitionAbandonedListener: (listener) ->
    @definitionAbandonedListeners.push listener

  notifyDefinitionAbandonedListeners: (use) ->
    for listener in @definitionAbandonedListeners
      listener.onDefinitionAbandoned use

  onEscapeKeyUp: (event) ->
    if event.keyCode is 27
      if @state is CodeViewerState.SHOW_UNDEFINED
        @clearDefinitionMarkers()
        @state = CodeViewerState.EDITING
      else if @state is CodeViewerState.SHOW_DEFINITIONS
        @clearDefinitionMarkers()
        @notifyDefinitionAbandonedListeners()
        @state = CodeViewerState.EXAMPLIFYING
      else if @state is CodeViewerState.EXAMPLIFYING
        @state = CodeViewerState.EDITING
      @repaint()

  ###
  Getters / Setters
  ###
  getTextEditor: ->
    @textEditor

  getBuffer: ->
    @textEditor.getBuffer()

  getChosenLines: ->
    @chosenLines

  setChosenLines: (lines) ->
    @chosenLines = lines
    @repaint()

  lineTextForBufferRow: (index) ->
    @textEditor.lineTextForBufferRow index
  """
