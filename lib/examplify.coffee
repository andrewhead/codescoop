{ CompositeDisposable, Range } = require 'atom'
{ CodeViewer } = require './code_viewer'
{ ExampleViewer } = require './example_viewer'
{ DefUseAnalysis } = require './def_use'
$ = require 'jquery'


# Listen for keypresses of Escape key.
# escapeHandler can be swapped out by the program.
workspaceView = atom.views.getView atom.workspace
keyupListener = (event) ->
  if (event.keyCode == 27)
    if (escapeHandler != undefined)
      escapeHandler();

atom.views.getView(atom.workspace).addEventListener 'keyup', keyupListener

# Globals
# List of markers that can be invalidated when a new choice was made
definitionMarkers = []
# A Java map of values that variables hold at lines in the file under focus.
variableValues = undefined
# Function to be called when escape is pressed
escapeHandler = undefined


module.exports = plugin =

  subscriptions: null

  codeViewer: null
  exampleViewer: null

  defUseAnalysis: null
  includedLines: []

  updateExampleCode: () ->
    sortedLineIndexes = @includedLines.sort()
    lineTexts = []
    for i in sortedLineIndexes
      lineTexts.push (@codeViewer.lineTextForBufferRow i)
    @exampleViewer.setChosenLines lineTexts

  clearDefinitionMarkers: (exclude) ->
    for i in [0..definitionMarkers.length - 1]
      definitionMarker = definitionMarkers[i]
      if (exclude == undefined || exclude.indexOf(definitionMarker) == -1)
        definitionMarker.destroy()

  # Given a variable name and a line number, get a value that it was
  # defined to have when the code was run.  While this currently relies on
  # a Map loaded from Java using the node-java connector, it's reasonable
  # to expect that this could also read in a pre-written local file instead.
  getVariableValue: (variableName, lineNumber) ->

    sourceFilename = atom.workspace.getActiveTextEditor().getTitle()
    value = undefined

    # Any one of the nested maps might return null if there's no value
    # for the key, so we do a null check for each layer of lookup.
    if (variableValues != undefined)
      lineToVariableMap = variableValues.getSync sourceFilename
      if (lineToVariableMap != null)
        variableToValueMap = lineToVariableMap.getSync lineNumber
        if (variableToValueMap != null)
          value = variableToValueMap.getSync variableName

    return value

  refreshVariableValues: () ->

    classname = plugin.getActiveFileClassname()
    pathToFile = plugin.getActiveFilePath()
    console.log pathToFile

    # Run the whole program with a debugger and get the values of variables on
    # each line, to let us do data substitution.
    variableTracer = new VariableTracer()
    variableTracer.run classname, pathToFile, (err, result) ->
      if (err)
        console.error "Error tracing variables: ", err
      else
        variableValues = result;

  getPrintableValue: (value) ->

    if java.instanceOf value, "com.sun.jdi.StringReference"
      return "\"" + value.valueSync() + "\""
    else if java.instanceOf value, "com.sun.jdi.CharValue"
      return "'" + value.valueSync() + "'"
    # I expect all of the following values can be casted to literals,
    # though there are some I'm skeptical of (e.g., ByteValue, BooleanValue)
    else if (java.instanceOf value, "com.sun.jdi.BooleanValue") or
        (java.instanceOf value, "com.sun.jdi.ByteValue") or
        (java.instanceOf value, "com.sun.jdi.ShortValue") or
        (java.instanceOf value, "com.sun.jdi.IntegerValue") or
        (java.instanceOf value, "com.sun.jdi.LongValue")
      return String value.valueSync()
    else if java.instanceOf value, "com.sun.jdi.ObjectReference"
      # I need to come up with something really clever here...
      return "new Object()"

    return "unknown!"

  highlightDefinitions: (undefinedMarker, symbol) ->

    # Create mark for the nearest definition of the symbol
    symbol =
      name: symbol.name,
      line: symbol.line,
      start: symbol.start,
      end: symbol.end

    if @defUseAnalysis?
      def = @defUseAnalysis.getDefBeforeUse symbol
      defRange = new Range(
        [def.line - 1, def.start],
        [def.line - 1, def.end]
      )
      editor = atom.workspace.getActiveTextEditor()
      defMarker = editor.markBufferRange(defRange, {
        invalidate: 'never'
      })
      definitionMarkers.push(defMarker)

    # This is the container of different options of ways to define code
    definitionOptions = $ "<div></div>"

    # This button lets one preview and insert constant value for the variable
    # We need access to the editor so we can show a preview of a new value.
    editor = atom.workspace.getActiveTextEditor()

    originalText = undefined
    if (variableValues != undefined)

      value = plugin.getVariableValue symbol.name, symbol.line

      originalText = editor.getTextInBufferRange undefinedMarker.getBufferRange()
      insertOption = $ "<div class=definition-option>Insert Data</div>"

      # Only give user the option of inserting the value if a value was found
      # at some point in the runtime data.
      if (value != undefined)

        insertOption.mouseover (event) ->
          printableValue = plugin.getPrintableValue value
          editor.setTextInBufferRange undefinedMarker.getBufferRange(), printableValue

        insertOption.mouseout (event) ->
          editor.setTextInBufferRange undefinedMarker.getBufferRange(), originalText

        insertOption.click (event) ->
          plugin.clearDefinitionMarkers()
          plugin.updateExampleCode()

          ###
          It's important to re-run analysis because there are no longer the
          same dependencies in the same locations when replacements were made.
          XXX: currently we save the file to make sure analysis is run on
          updated code.  In the future, it's better to make a temporary one.
          ###
          editor.save()
          plugin.analyze()

      else
        insertOption.addClass "disabled"

      definitionOptions.append insertOption

    # Listen for escape key and take a step back if it was pressed.
    escapeHandler = () ->
      # Before we remove the markers, we need to reset the text of the
      # symbol name, if it has been changed.
      if (originalText != undefined)
        editor.setTextInBufferRange undefinedMarker.getBufferRange(), originalText
      plugin.clearDefinitionMarkers()
      plugin.highlightUndefined()

    # This button lets one preview what lines of code need to be added
    if (defMarker != undefined)
      defDecoration = undefined

      defineOption = $ "<div class=definition-option>Add Definition</div>"
      defineOption.mouseover (event) ->
        defDecoration = editor.decorateMarker(defMarker, {
          type: 'line',
          class: 'definition'
        })

      defineOption.mouseout (event) ->
        if (defDecoration != undefined)
          defDecoration.destroy()

      defineOption.click (event) =>
        @includedLines.push (def.line - 1)
        @codeViewer.setChosenLines @includedLines
        @updateExampleCode()
        @clearDefinitionMarkers()
        @highlightUndefined()

      definitionOptions.append defineOption

    # The first marker is a clickable button for repair
    editor.decorateMarker undefinedMarker, {
      type: 'overlay',
      item: definitionOptions,
      position: 'tail',
      class: 'pick-overlay'
    }

  highlightUndefined: () ->

    if not @defUseAnalysis? then return

    undefinedUses = @defUseAnalysis.getUndefinedUses @includedLines

    # For each of the undefined uses, highlight them in the editor
    for use in undefinedUses

      # Skip all temporary variables
      # XXX: Problematically, this leaves out all imported classes.
      # We'll need to figure out a way to work this back in, leaving
      # out intermediate expressions and leaving in class names, for imports
      if use.name.startsWith "$" then return

      range = new Range(
        [use.line - 1, use.start],
        [use.line - 1, use.end]
      )

      editor = atom.workspace.getActiveTextEditor()
      marker = editor.markBufferRange range, {
        invalidate: 'never'
      }
      definitionMarkers.push marker

      # Save all of the metadata so we can find this use symbol
      # when we query the dataflow analysis again
      definitionButton = $ '<div>Click to define.</div>'
      definitionButton.data 'symbol', use
      definitionButton.data 'marker', marker
      definitionButton.click (event) =>
        symbol = $(event.target).data 'symbol'
        thisButtonMarker = $(event.target).data 'marker'
        @clearDefinitionMarkers [thisButtonMarker]
        @highlightDefinitions thisButtonMarker, use

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

    # Listen for escape key and exit example-making
    escapeHandler = () =>
      @codeViewer = undefined
      @clearDefinitionMarkers()
      @codeViewer.setChosenLines includedLines

  activate: (state) ->

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    this.subscriptions = new CompositeDisposable()

    # Register command for making example code
    this.subscriptions.add(atom.commands.add('atom-workspace', {
      'examplify:make-example-code': () ->

        # Highlight selected lines.  Obscure all others
        editor = atom.workspace.getActiveTextEditor()
        plugin.codeViewer = new CodeViewer editor
        range = editor.getSelectedBufferRange()
        plugin.includedLines = range.getRows()
        plugin.codeViewer.setChosenLines plugin.includedLines

        # Create a new editor that will hold a representation of the example code
        atom.workspace.open('SmallScoop.java', {
          split: 'right',
        }).then (editor) ->

          # Save a reference to the example editor
          plugin.exampleViewer = new ExampleViewer editor

          # Make sure that the focus returns to the sourceCodeEditor
          atom.workspace.paneForItem(plugin.codeViewer.getTextEditor()).activate()

          # Render the first version of the example code
          plugin.updateExampleCode()

          # Run dataflow analysis on the chosen lines
          plugin.defUseAnalysis = new DefUseAnalysis(
            plugin.codeViewer.getTextEditor().getPath(),
            plugin.codeViewer.getTextEditor().getTitle()
          )
          plugin.defUseAnalysis.run plugin.highlightUndefined.bind(plugin), (err) =>
            console.error err

    }))

  deactivate: () ->
    this.subscriptions.dispose()

  serialize: () ->
    return {}
