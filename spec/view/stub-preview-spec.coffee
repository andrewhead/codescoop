{ StubPreview } = require "../../lib/view/stub-preview"
{ StubSpec } = require "../../lib/model/stub"
{ ExampleModel } = require "../../lib/model/example-model"

describe "StubPreview", ->

  model = undefined
  stubPreview = undefined

  # Create a code editor and example editor for realism
  beforeEach =>

    model = new ExampleModel()
    stubPreview = new StubPreview model
    codeEditor = undefined
    exampleEditor = undefined
    runs =>
      (atom.workspace.open "CodeEdits.java", { split: "left" }).then (editor) =>
        codeEditor = editor
      (atom.workspace.open "ExampleEdits.java", { split: "right" }).then (editor) =>
        exampleEditor = editor

    waitsFor =>
      codeEditor? and exampleEditor?

  describe "when a stub spec is added", ->

    it "opens and activates an editor on the left", ->

      editorCountBefore = atom.workspace.getTextEditors().length
      activeEditorBefore = atom.workspace.getActiveTextEditor()
      (expect stubPreview.getTextEditor()).toBe null
      model.setStubOption new StubSpec "StubbedClass"

      waitsFor =>
        stubPreview.getTextEditor()?

      runs =>
        # An editor should have been created for the stub preview
        stubPreviewEditor = stubPreview.getTextEditor()
        (expect stubPreviewEditor?).toBe true

        # One more editor should be registered in the workspace
        editorCountAfter = atom.workspace.getTextEditors().length
        (expect editorCountAfter).toBe editorCountBefore + 1

        # Focus in the left pane should have shifted to the stub preview, though
        # focus in the right pane should still be on the example editor
        activeEditorAfter = atom.workspace.getActiveTextEditor()
        (expect activeEditorAfter).toBe activeEditorBefore
        stubPane = atom.workspace.paneForItem stubPreviewEditor
        (expect stubPane.getActiveItem()).toBe stubPreviewEditor

  describe "after a stub spec was added", ->

    # Wait for a preview editor for the stub to appear
    editorCountWithPreview = undefined
    beforeEach =>
      model.setStubOption new StubSpec "StubbedClass"
      waitsFor =>
        stubPreview.getTextEditor()?
      runs =>
        editorCountWithPreview = atom.workspace.getTextEditors().length

    it "prints text for the stub", ->
      (expect stubPreview.getTextEditor().getText()).toEqual [
        "private class StubbedClass {"
        "}"
        ""
      ].join "\n"

    it "updates text and activates the editor when the stub changes", ->
      model.setStubOption new StubSpec "UpdatedStubbedClass"
      waitsFor =>
        stubPreview.getTextEditor().getText() is [
          "private class UpdatedStubbedClass {"
          "}"
          ""
        ].join "\n"
      # Make sure that an extra editor was not created
      runs =>
        (expect atom.workspace.getTextEditors().length).toBe \
          editorCountWithPreview

    it "terminates the preview editor when a stub spec is removed", ->
      model.setStubOption null
      waitsFor =>
        (not stubPreview.getTextEditor()?) and
        (atom.workspace.getTextEditors().length is editorCountWithPreview - 1)
