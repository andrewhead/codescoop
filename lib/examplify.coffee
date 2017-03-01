{ CompositeDisposable } = require 'atom'
{ CodeViewer } = require './code_viewer'
{ ExampleViewer } = require './example_viewer'
{ DefUseAnalysis } = require './def_use'
{ ValueAnalysis } = require './value_analysis'
$ = require 'jquery'


module.exports = plugin =

  subscriptions: null

  codeViewer: null
  exampleViewer: null

  defUseAnalysis: null
  valueAnalysis: null

  runDefAnalysis: ->
    @defUseAnalysis.run((=>
      lines = @codeViewer.getChosenLines()
      undefinedUses = @defUseAnalysis.getUndefinedUses lines
      @codeViewer.highlightUndefinedUses undefinedUses
    ), ((error) =>
      console.error error
    ))

  runValueAnalysis: ->
    @valueAnalysis.run(
      (result) ->, # do nothing on success
      (error) =>
        console.error error
    )

  onUseSelected: (use) ->
    sourceFileName = @codeViewer.getTextEditor().getTitle()
    if @valueAnalysis?
      value = @valueAnalysis.getValue sourceFileName, use.name, use.line
    if @defUseAnalysis?
      def = @defUseAnalysis.getDefBeforeUse use
    @codeViewer.highlightDefinitions use, def, value

  onUseDefined: (use) ->
    lineNumbers = @codeViewer.getChosenLines()
    @exampleViewer.setChosenLines(lineNumbers)
    @runDefAnalysis()

  onDefinitionAbandoned: (use) ->
    @runDefAnalysis()

  activate: (state) ->

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    this.subscriptions = new CompositeDisposable()

    # Register command for making example code
    this.subscriptions.add(atom.commands.add('atom-workspace', {
      'examplify:make-example-code': () ->

        # Highlight selected lines.  Obscure all others
        editor = atom.workspace.getActiveTextEditor()
        plugin.codeViewer = new CodeViewer atom.workspace, editor
        range = editor.getSelectedBufferRange()
        selectedLines = range.getRows()
        plugin.codeViewer.setChosenLines selectedLines
        plugin.codeViewer.addUseSelectedListener plugin
        plugin.codeViewer.addUseDefinedListener plugin
        plugin.codeViewer.addDefinitionAbandonedListener plugin
        codeViewerBuffer = plugin.codeViewer.getBuffer()

        # Create a new editor that will hold a representation of the example code
        atom.workspace.open('SmallScoop.java', {
          split: 'right',
        }).then (editor) ->

          # Save a reference to the example editor
          plugin.exampleViewer = new ExampleViewer editor, codeViewerBuffer, selectedLines

          # Make sure that the focus returns to the sourceCodeEditor
          atom.workspace.paneForItem(plugin.codeViewer.getTextEditor()).activate()

          # Run dataflow analysis on the chosen lines
          filePath = plugin.codeViewer.getTextEditor().getPath()
          fileName = plugin.codeViewer.getTextEditor().getTitle()
          plugin.defUseAnalysis = new DefUseAnalysis filePath, fileName
          plugin.valueAnalysis = new ValueAnalysis filePath, fileName

          plugin.runDefAnalysis()
          plugin.runValueAnalysis()

    }))

  deactivate: () ->
    this.subscriptions.dispose()

  serialize: () ->
    return {}
