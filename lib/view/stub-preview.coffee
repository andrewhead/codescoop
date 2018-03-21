{ ExampleModelProperty } = require "../model/example-model"
{ StubPrinter } = require "./stub-printer"
$ = require "jquery"


module.exports.StubPreview = class StubPreview

  constructor: (model) ->
    model.addObserver @
    @textEditor = null

  getTextEditor: ->
    @textEditor

  _updateStubText: (stubSpec) ->
    stubPrinter = new StubPrinter()
    stubText = stubPrinter.printToString stubSpec
    @textEditor.setText stubText

  onPropertyChanged: (object, propertyName, oldValue, newValue) ->

    if propertyName is ExampleModelProperty.STUB_OPTION

      # If the stub option was set to null, hide the preview
      if (not newValue?) and @textEditor?
        @textEditor.destroy()
        @textEditor = null

      else if newValue?

        # If the text editor has been initialized, just update the text
        if @textEditor?
          @_updateStubText newValue

        # If an editor doesn't exist for the preview, we have to create one
        # befoe we can show the stub text.
        else
          # XXX: right now, the stub preview is specific to Java.  In the future,
          # the language for the stub should be detected to open up with the
          # right extension for each language, to enable syntax highlighting
          (atom.workspace.open "StubPreview.java", {
              split: "left"
              activatePane: false
              activateItem: true
            }).then (editor) =>

              # Editor syntax should be for Java instead of default
              if atom.grammars.grammarForScopeName?
                grammar = atom.grammars.grammarForScopeName 'source.java'
              else if atom.grammars.grammarsByScopeName?
                grammar = atom.grammars.grammarsByScopeName['source.java']
              if grammar?
                editor.setGrammar grammar

              @textEditor = editor
              editorView = atom.views.getView @textEditor
              ($ editorView).addClass 'stub-editor'
              @_updateStubText newValue
