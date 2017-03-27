{ Fixer } = require "../../lib/command/fixer"
{ ExampleModel } = require "../../lib/model/example-model"
{ Symbol, SymbolSet, File } = require "../../lib/model/symbol-set"
{ Range, RangeSet } = require "../../lib/model/range-set"
{ TextBuffer } = require "atom"
{ StubSpec } = require "../../lib/model/stub"
{ Import } = require "../../lib/model/import"
{ Replacement } = require "../../lib/edit/replacement"
{ Declaration } = require "../../lib/edit/declaration"
{ ControlCrossingEvent } = require "../../lib/event/control-crossing"

{ AddLineForRange } = require "../../lib/command/add-line-for-range"
{ AddRange } = require "../../lib/command/add-range"
{ AddImport } = require "../../lib/command/add-import"
{ AddEdit } = require "../../lib/command/add-edit"
{ RemoveUse } = require "../../lib/command/remove-use"
{ AddDeclaration } = require "../../lib/command/add-declaration"
{ AddStubSpec } = require "../../lib/command/add-stub-spec"
{ ArchiveEvent } = require "../../lib/command/archive-event"

{ ImportSuggestion } = require "../../lib/suggester/import-suggester"
{ DefinitionSuggestion } = require "../../lib/suggester/definition-suggester"
{ PrimitiveValueSuggestion } = require "../../lib/suggester/primitive-value-suggester"
{ InstanceStubSuggestion } = require '../../lib/suggester/instance-stub-suggester'
{ DeclarationSuggestion } = require "../../lib/suggester/declaration-suggester"
{ ControlStructureExtension } = require "../../lib/extender/control-structure-extender"
{ ExtensionDecision } = require "../../lib/extender/extension-decision"


_rangeInRanges = (range, ranges) =>
  for otherRange in ranges
    if range.isEqual otherRange
      return true
  false


describe "Fixer", ->

  TEST_FILE = new File '.', 'test-file.java'

  describe "when handling a DefinitionSuggestion", ->

    model = undefined
    commandGroup = undefined
    suggestion = new DefinitionSuggestion \
      new Symbol TEST_FILE, "i", new Range [0, 4], [0, 5]

    beforeEach =>
      buffer = new TextBuffer()
      buffer.setText [
        "int i = 15;"
        "int j = i + i + 1;"
      ].join "\n"
      model = new ExampleModel buffer
      fixer = new Fixer()
      commandGroup = fixer.apply model, suggestion

    it "adds a range that includes a symbol of a DefinitionSuggestion", ->
      activeRanges = model.getRangeSet().getActiveRanges()
      activeRangeFound = false
      for range in activeRanges
        if range.containsRange suggestion.getSymbol().getRange()
          activeRangeFound = true
      (expect activeRangeFound).toBe true

    it "returns a command group with a range addition", ->
      (expect commandGroup.length).toBe 1
      command = commandGroup[0]
      (expect command instanceof AddLineForRange)
      (expect command.getRange().containsRange new Range [0, 4], [0, 5]).toBe true

  describe "when handling an ImportSuggestion", ->

    model = undefined
    commandGroup = undefined

    beforeEach =>
      model = new ExampleModel()
      fixer = new Fixer()
      suggestion = new ImportSuggestion \
        new Import "org.ImportedClass", new Range [0, 7], [0, 24]
      commandGroup = fixer.apply model, suggestion

    it "adds an import range corresponding to the line the import appears on", ->
      # Check the set of active ranges for at least one that includes the
      # entire line that the import occurred on
      imports = model.getImports()
      (expect imports.length).toBe 1
      (expect imports[0].getName()).toEqual "org.ImportedClass"

    it "returns a command group with the imports added", ->
      (expect commandGroup.length).toBe 1
      (expect commandGroup[0] instanceof AddImport).toBe true
      (expect commandGroup[0].getImport().getName()).toEqual "org.ImportedClass"

  describe "when handling a PrimitiveValueSuggestion", ->

    model = undefined
    commandGroup = undefined
    beforeEach =>
      model = new ExampleModel()
      model.getSymbols().setVariableUses [
        new Symbol TEST_FILE, "i", new Range [1, 8], [1, 9]
        new Symbol TEST_FILE, "i", new Range [1, 12], [1, 13]
      ]
      suggestion = new PrimitiveValueSuggestion \
        (new Symbol TEST_FILE, "i", new Range [1, 8], [1, 9]), "15"
      fixer = new Fixer()
      commandGroup = fixer.apply model, suggestion

    it "registers a new 'replacement' edit", ->
      edits = model.getEdits()
      (expect edits.length).toBe 1
      edit = edits[0]
      (expect edit instanceof Replacement).toBe true
      (expect edit.getSymbol().getRange()).toEqual new Range [1, 8], [1, 9]
      (expect edit.getText()).toEqual "15"

    it "updates the model to reflect that the symbol is no longer being used", ->
      uses = model.getSymbols().getVariableUses()
      (expect uses.length).toBe 1
      (expect uses[0].getRange()).toEqual new Range [1, 12], [1, 13]

    it "returns a command group with the edit and use removal", ->
      (expect commandGroup.length).toBe 2
      (expect commandGroup[0] instanceof AddEdit).toBe true
      (expect commandGroup[1] instanceof RemoveUse).toBe true

  describe "when applying a DeclarationSuggestion", ->

    model = undefined
    commandGroup = undefined

    beforeEach =>
      model = new ExampleModel()
      fixer = new Fixer()
      suggestion = new DeclarationSuggestion \
        "i", "int", new Symbol TEST_FILE, "i", (new Range [0, 4], [0, 5]), "int"
      commandGroup = fixer.apply model, suggestion

    it "adds an extra declaration to the model", ->
      declarations = model.getAuxiliaryDeclarations()
      (expect declarations.length).toBe 1
      declaration = declarations[0]
      (expect declaration instanceof Declaration).toBe true
      (expect declaration.getName()).toEqual "i"
      (expect declaration.getType()).toEqual "int"

    it "returns a command group with the declaration addition", ->
      (expect commandGroup.length).toBe 1
      (expect commandGroup[0] instanceof AddDeclaration).toBe true
      (expect commandGroup[0].getDeclaration().getName()).toEqual "i"

  describe "when applying an InstanceStubSuggestion", ->

    model = undefined
    commandGroup = undefined

    beforeEach =>
      model = new ExampleModel()
      fixer = new Fixer()
      model.getSymbols().setVariableUses [
        new Symbol TEST_FILE, "book", (new Range [4, 11], [4, 15]), "Book"
      ]
      suggestion = new InstanceStubSuggestion \
        (new Symbol TEST_FILE, "book", (new Range [4, 11], [4, 15]), "Book"),
        (new StubSpec "Book")
      commandGroup = fixer.apply model, suggestion

    it "adds the stub spec to the model", ->
      stubSpecs = model.getStubSpecs()
      (expect stubSpecs.length).toBe 1
      (expect stubSpecs[0].className).toEqual "Book"

    it "adds a command to replace the symbol with an instantiation", ->
      edits = model.getEdits()
      (expect edits.length).toBe 1
      edit = edits[0]
      (expect edit instanceof Replacement).toBe true
      (expect edit.getSymbol().getRange()).toEqual new Range [4, 11], [4, 15]
      (expect edit.getText()).toEqual "(new Book())"

    it "updates the model to reflect the symbol is no longer being used", ->
      uses = model.getSymbols().getVariableUses()
      (expect uses.length).toBe 0

    it "returns a command group with the stub, edit, and use removal", ->
      (expect commandGroup.length).toBe 3
      (expect commandGroup[0] instanceof AddStubSpec).toBe true
      (expect commandGroup[0].getStubSpec().className).toEqual "Book"
      (expect commandGroup[1] instanceof AddEdit).toBe true
      (expect commandGroup[2] instanceof RemoveUse).toBe true
      (expect commandGroup[2].getSymbol().getName()).toEqual "book"

  describe "when applying extension decisions", ->

    describe "if a decision was accepted", ->

      decision = undefined
      model = undefined
      fixer = undefined
      commandGroup = undefined

      beforeEach =>
        model = new ExampleModel()
        event = { eventId: 42 }
        model.getEvents().push event
        decision = new ExtensionDecision \
          event, { extensionId: 42 }, true
        fixer = new Fixer()
        commandGroup = fixer.apply model, decision

      it "removes the event from the model's events", ->
        (expect model.getEvents().length).toBe 0

      it "adds the event to the model's viewed events", ->
        (expect model.getViewedEvents()).toEqual [ { eventId: 42 }]

      it "returns a command group with a command that archives the event", ->
        (expect commandGroup[0] instanceof ArchiveEvent).toBe true
        (expect commandGroup[0].getEvent()).toEqual { eventId: 42 }

    describe "if a decision was rejected", ->

      decision = undefined
      model = undefined
      fixer = undefined

      beforeEach =>
        model = new ExampleModel()
        event = { eventId: 42 }
        model.getEvents().push event
        decision = new ExtensionDecision \
          event, { extensionId: 42 }, false
        fixer = new Fixer()

      it "removes the event from the model's events", ->
        fixer.apply model, decision
        (expect model.getEvents().length).toBe 0

      it "adds the event to the model's viewed events", ->
        fixer.apply model, decision
        (expect model.getViewedEvents()).toEqual [ { eventId: 42 }]

    describe "when applying a ControlStructureExtension", ->

      describe "if the decision was accepted", ->

        model = undefined
        commandGroup = undefined
        beforeEach =>
          model = new ExampleModel()
          fixer = new Fixer()
          decision = new ExtensionDecision \
            (new ControlCrossingEvent()),
            (new ControlStructureExtension undefined,
              [(new Range [0, 2], [0, 3]), new Range [1, 4], [1, 9]]),
            true
          commandGroup = fixer.apply model, decision

        it "adds the structure's ranges to the model", ->
          activeRanges = model.getRangeSet().getActiveRanges()
          (expect _rangeInRanges (new Range [0, 2], [0, 3]), activeRanges).toBe true
          (expect _rangeInRanges (new Range [1, 4], [1, 9]), activeRanges).toBe true

        it "returns a command group with the range additions", ->
          (expect commandGroup.length).toBe 3
          (expect commandGroup[1] instanceof AddRange).toBe true
          (expect commandGroup[2] instanceof AddRange).toBe true

      describe "if the decision was rejected", ->

        model = undefined
        commandGroup = undefined
        beforeEach =>
          model = new ExampleModel()
          fixer = new Fixer()
          decision = new ExtensionDecision \
            (new ControlCrossingEvent()),
            (new ControlStructureExtension undefined,
              [(new Range [0, 2], [0, 3]), new Range [1, 4], [1, 9]]),
            false
          commandGroup = fixer.apply model, decision

        it "doesn't add the structure's ranges to the model", ->
          activeRanges = model.getRangeSet().getActiveRanges()
          (expect _rangeInRanges (new Range [0, 2], [0, 3]), activeRanges).toBe false
          (expect _rangeInRanges (new Range [1, 4], [1, 9]), activeRanges).toBe false

        it "returns a command group with just an archived event", ->
          (expect commandGroup.length).toBe 1
          (expect commandGroup[0] instanceof ArchiveEvent).toBe true
