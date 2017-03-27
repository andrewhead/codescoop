{ CommandFinder } = require "../../lib/command/command-finder"
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


describe "CommandFinder", ->

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
      commandFinder = new CommandFinder()
      commandGroup = commandFinder.getCommandsForSuggestion suggestion

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
      commandFinder = new CommandFinder()
      suggestion = new ImportSuggestion \
        new Import "org.ImportedClass", new Range [0, 7], [0, 24]
      commandGroup = commandFinder.getCommandsForSuggestion suggestion

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
      commandFinder = new CommandFinder()
      commandGroup = commandFinder.getCommandsForSuggestion suggestion

    it "returns a command group with the edit and use removal", ->
      (expect commandGroup.length).toBe 2
      (expect commandGroup[0] instanceof AddEdit).toBe true
      (expect commandGroup[1] instanceof RemoveUse).toBe true

  describe "when applying a DeclarationSuggestion", ->

    model = undefined
    commandGroup = undefined

    beforeEach =>
      model = new ExampleModel()
      commandFinder = new CommandFinder()
      suggestion = new DeclarationSuggestion \
        "i", "int", new Symbol TEST_FILE, "i", (new Range [0, 4], [0, 5]), "int"
      commandGroup = commandFinder.getCommandsForSuggestion suggestion

    it "returns a command group with the declaration addition", ->
      (expect commandGroup.length).toBe 1
      (expect commandGroup[0] instanceof AddDeclaration).toBe true
      (expect commandGroup[0].getDeclaration().getName()).toEqual "i"

  describe "when applying an InstanceStubSuggestion", ->

    model = undefined
    commandGroup = undefined

    beforeEach =>
      model = new ExampleModel()
      commandFinder = new CommandFinder()
      model.getSymbols().setVariableUses [
        new Symbol TEST_FILE, "book", (new Range [4, 11], [4, 15]), "Book"
      ]
      suggestion = new InstanceStubSuggestion \
        (new Symbol TEST_FILE, "book", (new Range [4, 11], [4, 15]), "Book"),
        (new StubSpec "Book")
      commandGroup = commandFinder.getCommandsForSuggestion suggestion

    it "returns a command group with the stub, edit, and use removal", ->
      (expect commandGroup.length).toBe 3
      (expect commandGroup[0] instanceof AddStubSpec).toBe true
      (expect commandGroup[0].getStubSpec().className).toEqual "Book"
      (expect commandGroup[1] instanceof AddEdit).toBe true
      (expect commandGroup[2] instanceof RemoveUse).toBe true
      (expect commandGroup[2].getSymbol().getName()).toEqual "book"

  describe "when applying extension decisions", ->

    describe "when applying a ControlStructureExtension", ->

      describe "if the decision was accepted", ->

        model = undefined
        commandGroup = undefined
        beforeEach =>
          model = new ExampleModel()
          commandFinder = new CommandFinder()
          decision = new ExtensionDecision \
            (new ControlCrossingEvent()),
            (new ControlStructureExtension undefined,
              [(new Range [0, 2], [0, 3]), new Range [1, 4], [1, 9]]),
            true
          commandGroup = commandFinder.getCommandsForExtensionDecision decision

        it "returns a command group with the range additions", ->
          (expect commandGroup.length).toBe 3
          (expect commandGroup[1] instanceof AddRange).toBe true
          (expect commandGroup[2] instanceof AddRange).toBe true

      describe "if the decision was rejected", ->

        model = undefined
        commandGroup = undefined
        beforeEach =>
          model = new ExampleModel()
          commandFinder = new CommandFinder()
          decision = new ExtensionDecision \
            (new ControlCrossingEvent()),
            (new ControlStructureExtension undefined,
              [(new Range [0, 2], [0, 3]), new Range [1, 4], [1, 9]]),
            false
          commandGroup = commandFinder.getCommandsForExtensionDecision decision

        it "returns a command group with just an archived event", ->
          (expect commandGroup.length).toBe 1
          (expect commandGroup[0] instanceof ArchiveEvent).toBe true
