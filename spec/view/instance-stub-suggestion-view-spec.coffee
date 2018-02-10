{ InstanceStubSuggestionView } = require "../../lib/view/instance-stub-suggestion"
{ InstanceStubSuggestion } = require "../../lib/suggester/instance-stub-suggester"
{ ExampleModel } = require "../../lib/model/example-model"
{ Range } = require "../../lib/model/range-set"
{ File, Symbol } = require "../../lib/model/symbol-set"
{ StubSpec } = require "../../lib/model/stub"


describe "InstanceStubSuggestionView", ->

  model = undefined
  view = undefined
  symbol = undefined
  beforeEach =>
    model = new ExampleModel()
    testFile = new File "path", "file_name"
    symbol = new Symbol testFile, "book", (new Range [3, 4], [3, 8]), "Book"
    stubSpec = new StubSpec "Book"
    suggestion = new InstanceStubSuggestion symbol, stubSpec
    view = new InstanceStubSuggestionView suggestion, model, undefined, 41

  it "has a label that includes the index of the suggestion", ->
    (expect view.text()).toEqual "← Preview Stub 42"

  describe "when previewing a suggestion", ->

    beforeEach =>
      view.preview()

    it "creates an edit for instantiating the stub", ->
      edits = model.getEdits()
      (expect edits.length).toBe 1
      (expect edits[0].symbol).toBe symbol
      (expect edits[0].text).toBe "(new Book())"

    it "updates the stub option in the model", ->
      (expect model.getStubOption()).not.toBe null

  describe "when reverting a suggestion", ->

    beforeEach =>
      view.preview()
      view.revert()

    it "resets the edits for the stub", ->
      edits = model.getEdits()
      (expect edits.length).toBe 0

    it "sets the stub option back to null", ->
      (expect model.getStubOption()).toBe null
