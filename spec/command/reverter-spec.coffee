{ Reverter } = require "../../lib/command/reverter"
{ ExampleModel } = require "../../lib/model/example-model"
{ Symbol, SymbolSet, File } = require "../../lib/model/symbol-set"
{ Range, RangeSet } = require "../../lib/model/range-set"
{ StubSpec } = require "../../lib/model/stub"
{ Import } = require "../../lib/model/import"
{ Replacement } = require "../../lib/edit/replacement"
{ Declaration } = require "../../lib/edit/declaration"
{ ControlCrossingEvent } = require "../../lib/event/control-crossing"

{ ImportSuggestion } = require "../../lib/suggester/import-suggester"
{ DefinitionSuggestion } = require "../../lib/suggester/definition-suggester"
{ PrimitiveValueSuggestion } = require "../../lib/suggester/primitive-value-suggester"
{ InstanceStubSuggestion } = require '../../lib/suggester/instance-stub-suggester'
{ DeclarationSuggestion } = require "../../lib/suggester/declaration-suggester"
{ ControlStructureExtension } = require "../../lib/extender/control-structure-extender"
{ ExtensionDecision } = require "../../lib/extender/extension-decision"


xdescribe "Reverter", ->

  _makeModel = =>
    editor = atom.workspace.buildTextEditor()
    codeBuffer = editor.getBuffer()
    codeBuffer.setText [
      "int i = 15;"
      "int j = i + i + 1;"
    ].join "\n"
    rangeSet = new RangeSet()
    symbols = new SymbolSet()
    new ExampleModel codeBuffer, rangeSet, symbols

  TEST_FILE = new File '.', 'test-file.java'

  fit "removes the range that includes a symbol of a DefinitionSuggestion", ->

    model = new ExampleModel()
    activeRanges = model.getRangeSet().getActiveRanges()
    activeRanges.push new Range [1, 4], [1, 5]  # shouldn't be removed
    activeRanges.push new Range [0, 4], [0, 5]
    suggestion = new DefinitionSuggestion \
      new Symbol TEST_FILE, "i", new Range [0, 4], [0, 5]

    reverter = new Reverter()
    (expect activeRanges.length).toBe 2
    reverter.revert model, suggestion
    (expect activeRanges.length).toBe 1
    (expect activeRanges[0]).toEqual new Range [1, 4], [1, 5]

  describe "when reverting an ImportSuggestion", ->

    codeBuffer = atom.workspace.buildTextEditor().getBuffer()
    codeBuffer.setText [
      "import org.ImportedClass;"
      "public class Book {}"
    ].join "\n"
    model = new ExampleModel codeBuffer
    reverter = new Reverter()

    it "removes the import range for the line the import appears on", ->

      suggestion = new ImportSuggestion \
        new Import "org.ImportedClass", new Range [0, 7], [0, 24]
      reverter.revert model, suggestion

      # Check the set of active ranges for at least one that includes the
      # entire line that the import occurred on
      imports = model.getImports()
      (expect imports.length).toBe 1
      (expect imports[0].getName()).toEqual "org.ImportedClass"

  describe "when reverting a PrimitiveValueSuggestion", ->

    model = _makeModel()
    model.getSymbols().setVariableUses [
      new Symbol TEST_FILE, "i", new Range [1, 8], [1, 9]
      new Symbol TEST_FILE, "i", new Range [1, 12], [1, 13]
    ]
    suggestion = new PrimitiveValueSuggestion \
      (new Symbol TEST_FILE, "i", new Range [1, 8], [1, 9]), "15"
    reverter = new Reverter()
    reverter.revert model, suggestion

    it "unregisters the 'replacement' edit", ->
      edits = model.getEdits()
      (expect edits.length).toBe 1
      edit = edits[0]
      (expect edit instanceof Replacement).toBe true
      (expect edit.getSymbol().getRange()).toEqual new Range [1, 8], [1, 9]
      (expect edit.getText()).toEqual "15"

    it "updates the model to reflect that the symbol is being used", ->
      uses = model.getSymbols().getVariableUses()
      (expect uses.length).toBe 1
      (expect uses[0].getRange()).toEqual new Range [1, 12], [1, 13]

  describe "when reverting a DeclarationSuggestion", ->

    it "removes the declaration to the model", ->
      model = _makeModel()
      reverter = new Reverter()
      (expect model.getAuxiliaryDeclarations().length).toBe 0
      suggestion = new DeclarationSuggestion \
        "i", "int", new Symbol TEST_FILE, "i", (new Range [0, 4], [0, 5]), "int"
      reverter.revert model, suggestion
      declarations = model.getAuxiliaryDeclarations()
      (expect declarations.length).toBe 1
      declaration = declarations[0]
      (expect declaration instanceof Declaration).toBe true
      (expect declaration.getName()).toEqual "i"
      (expect declaration.getType()).toEqual "int"

  describe "when applying an InstanceStubSuggestion", ->

    model = _makeModel()
    reverter = new Reverter()
    model.getSymbols().setVariableUses [
      new Symbol TEST_FILE, "book", (new Range [4, 11], [4, 15]), "Book"
    ]
    (expect model.getStubSpecs().length).toBe 0
    suggestion = new InstanceStubSuggestion \
      (new Symbol TEST_FILE, "book", (new Range [4, 11], [4, 15]), "Book"),
      (new StubSpec "Book")
    reverter.revert model, suggestion

    it "removes the stub spec from the model", ->
      stubSpecs = model.getStubSpecs()
      (expect stubSpecs.length).toBe 1
      (expect stubSpecs[0].className).toBe "Book"

    it "removes the command that replaces the symbol with an instantiation", ->
      edits = model.getEdits()
      (expect edits.length).toBe 1
      edit = edits[0]
      (expect edit instanceof Replacement).toBe true
      (expect edit.getSymbol().getRange()).toEqual new Range [4, 11], [4, 15]
      (expect edit.getText()).toEqual "(new Book())"

    it "updates the model to reflect the symbol is being used", ->
      uses = model.getSymbols().getVariableUses()
      (expect uses.length).toBe 0

  describe "when reverting extension decisions", ->

    describe "if a decision was accepted", ->

      decision = undefined
      model = undefined
      reverter = undefined

      beforeEach =>
        model = new ExampleModel()
        event = { eventId: 42 }
        model.getEvents().push event
        decision = new ExtensionDecision \
          event, { extensionId: 42 }, true
        reverter = new Reverter()

      it "adds the event to the start of the model's events", ->
        reverter.revert model, decision
        (expect model.getEvents().length).toBe 0

      it "removes the event from the model's viewed events", ->
        reverter.revert model, decision
        (expect model.getViewedEvents()).toEqual [ { eventId: 42 }]

    describe "if a decision was rejected", ->

      decision = undefined
      model = undefined
      reverter = undefined

      beforeEach =>
        model = new ExampleModel()
        event = { eventId: 42 }
        model.getEvents().push event
        decision = new ExtensionDecision \
          event, { extensionId: 42 }, false
        reverter = new Reverter()

      it "adds the event to the start of the model's events", ->
        reverter.revert model, decision
        (expect model.getEvents().length).toBe 0

      it "removes the event from the model's viewed events", ->
        reverter.revert model, decision
        (expect model.getViewedEvents()).toEqual [ { eventId: 42 }]

    describe "when reverting a ControlStructureExtension", ->

      describe "if the decision was accepted", ->

        it "removes the structure's ranges from the model", ->

          model = _makeModel()
          reverter = new Reverter()
          decision = new ExtensionDecision \
            (new ControlCrossingEvent()),
            (new ControlStructureExtension undefined,
              [(new Range [0, 2], [0, 3]), new Range [1, 4], [1, 9]]),
            true
          reverter.revert model, decision

          activeRanges = model.getRangeSet().getActiveRanges()
          (expect _rangeInRanges (new Range [0, 2], [0, 3]), activeRanges).toBe true
          (expect _rangeInRanges (new Range [1, 4], [1, 9]), activeRanges).toBe true

      describe "if the decision was rejected", ->

        it "doesn't remove the structure's ranges to the model", ->

          model = _makeModel()
          reverter = new Reverter()
          decision = new ExtensionDecision \
            (new ControlCrossingEvent()),
            (new ControlStructureExtension undefined,
              [(new Range [0, 2], [0, 3]), new Range [1, 4], [1, 9]]),
            false
          reverter.revert model, decision

          activeRanges = model.getRangeSet().getActiveRanges()
          (expect _rangeInRanges (new Range [0, 2], [0, 3]), activeRanges).toBe false
          (expect _rangeInRanges (new Range [1, 4], [1, 9]), activeRanges).toBe false
