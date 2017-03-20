{ ExampleModelProperty } = require "../model/example-model"
{ StubPrinter } = require "./stub-printer"


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

  onPropertyChanged: (object, propertyName, propertyValue) ->

    if propertyName is ExampleModelProperty.STUB_OPTION

      # If the stub option was set to null, hide the preview
      if (not propertyValue?) and @textEditor?
        @textEditor.destroy()
        @textEditor = null

      else if propertyValue?

        # If the text editor has been initialized, just update the text
        if @textEditor?
          @_updateStubText propertyValue

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
              @textEditor = editor
              @_updateStubText propertyValue
