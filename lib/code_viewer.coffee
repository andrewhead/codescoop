$ = require('jquery');

module.exports.CodeViewer = class CodeViewer

  chosenLines: []

  constructor: (textEditor) ->

    @textEditor = textEditor

    # Make sure to update highlighting whenever the DOM changes
    @listenForRefocus()

    # XXX: Unfold all folds in editors to make sure our highlighting tricks
    # align to the right line indexes in the DOM.
    @textEditor.unfoldAll()

  setChosenLines: (lines) ->
    @chosenLines = lines
    @repaint()

  lineTextForBufferRow: (index) ->
    @textEditor.lineTextForBufferRow index

  getTextEditor: () ->
    @textEditor

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

  repaint: ->

    # All lines should be reset to being non-highlighted.
    $('div.line').removeClass('chosen').removeClass 'unchosen';

    # XXX: Another HTML hack: find the lines on the page that correspond
    # to the main editor, and highlight those lines.
    if (@textEditor != undefined)
      codeLines = $(
        'atom-pane[data-active-item-name="' + @textEditor.getTitle() + '"] ' +
        'div.line')

      codeLines.each (i, line) =>
        lineIndex = Number $(line).data 'screenRow'
        if (@chosenLines.indexOf(lineIndex) != -1)
          $(line).addClass 'chosen'
        else
          $(line).addClass 'unchosen'
