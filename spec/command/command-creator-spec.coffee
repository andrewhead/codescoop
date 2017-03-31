{ CommandCreator } = require "../../lib/command/command-creator"
{ ExampleModel } = require "../../lib/model/example-model"
{ Symbol, SymbolSet, File } = require "../../lib/model/symbol-set"
{ Range, RangeSet } = require "../../lib/model/range-set"
{ TextBuffer } = require "atom"
{ StubSpec } = require "../../lib/model/stub"
{ Import } = require "../../lib/model/import"
{ Replacement } = require "../../lib/edit/replacement"
{ Declaration } = require "../../lib/edit/declaration"

{ ControlCrossingEvent } = require "../../lib/event/control-crossing"
{ MediatingUseEvent } = require "../../lib/event/mediating-use"
{ MethodThrowsEvent } = require "../../lib/event/method-throws"

{ ImportSuggestion } = require "../../lib/suggester/import-suggester"
{ DefinitionSuggestion } = require "../../lib/suggester/definition-suggester"
{ PrimitiveValueSuggestion } = require "../../lib/suggester/primitive-value-suggester"
{ InstanceStubSuggestion } = require '../../lib/suggester/instance-stub-suggester'
{ DeclarationSuggestion } = require "../../lib/suggester/declaration-suggester"
{ InnerClassSuggestion } = require "../../lib/suggester/inner-class-suggester"
{ ExtensionDecision } = require "../../lib/extender/extension-decision"
{ ControlStructureExtension } = require "../../lib/extender/control-structure-extender"
{ MediatingUseExtension } = require "../../lib/extender/mediating-use-extender"
{ MethodThrowsExtension } = require "../../lib/extender/method-throws-extender"

{ AddLineForRange } = require "../../lib/command/add-line-for-range"
{ AddRange } = require "../../lib/command/add-range"
{ AddClassRange } = require "../../lib/command/add-class-range"
{ AddImport } = require "../../lib/command/add-import"
{ AddThrows } = require "../../lib/command/add-throws"
{ AddEdit } = require "../../lib/command/add-edit"
{ RemoveUse } = require "../../lib/command/remove-use"
{ AddDeclaration } = require "../../lib/command/add-declaration"
{ AddStubSpec } = require "../../lib/command/add-stub-spec"
{ ArchiveEvent } = require "../../lib/command/archive-event"


describe "CommandCreator", ->

  TEST_FILE = new File '.', 'test-file.java'

  describe "when given a DefinitionSuggestion", ->

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
      commandCreator = new CommandCreator()
      commandGroup = commandCreator.createCommandGroupForSuggestion suggestion

    it "creates a command group with a range addition", ->
      (expect commandGroup.length).toBe 1
      command = commandGroup[0]
      (expect command instanceof AddLineForRange)
      (expect command.getRange().containsRange new Range [0, 4], [0, 5]).toBe true

  describe "when given an ImportSuggestion", ->

    model = undefined
    commandGroup = undefined

    beforeEach =>
      model = new ExampleModel()
      commandCreator = new CommandCreator()
      suggestion = new ImportSuggestion \
        new Import "org.ImportedClass", new Range [0, 7], [0, 24]
      commandGroup = commandCreator.createCommandGroupForSuggestion suggestion

    it "creates a command group with the imports added", ->
      (expect commandGroup.length).toBe 1
      (expect commandGroup[0] instanceof AddImport).toBe true
      (expect commandGroup[0].getImport().getName()).toEqual "org.ImportedClass"

  describe "when given a PrimitiveValueSuggestion", ->

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
      commandCreator = new CommandCreator()
      commandGroup = commandCreator.createCommandGroupForSuggestion suggestion

    it "creates a command group with the edit and use removal", ->
      (expect commandGroup.length).toBe 2
      (expect commandGroup[0] instanceof AddEdit).toBe true
      (expect commandGroup[1] instanceof RemoveUse).toBe true

  describe "when given a DeclarationSuggestion", ->

    model = undefined
    commandGroup = undefined

    beforeEach =>
      model = new ExampleModel()
      commandCreator = new CommandCreator()
      suggestion = new DeclarationSuggestion \
        "i", "int", new Symbol TEST_FILE, "i", (new Range [0, 4], [0, 5]), "int"
      commandGroup = commandCreator.createCommandGroupForSuggestion suggestion

    it "creates a command group with the declaration addition", ->
      (expect commandGroup.length).toBe 1
      (expect commandGroup[0] instanceof AddDeclaration).toBe true
      (expect commandGroup[0].getDeclaration().getName()).toEqual "i"

  describe "when given an InstanceStubSuggestion", ->

    model = undefined
    commandGroup = undefined

    beforeEach =>
      model = new ExampleModel()
      commandCreator = new CommandCreator()
      model.getSymbols().setVariableUses [
        new Symbol TEST_FILE, "book", (new Range [4, 11], [4, 15]), "Book"
      ]
      suggestion = new InstanceStubSuggestion \
        (new Symbol TEST_FILE, "book", (new Range [4, 11], [4, 15]), "Book"),
        (new StubSpec "Book")
      commandGroup = commandCreator.createCommandGroupForSuggestion suggestion

    it "creates a command group with the stub, edit, and use removal", ->
      (expect commandGroup.length).toBe 3
      (expect commandGroup[0] instanceof AddStubSpec).toBe true
      (expect commandGroup[0].getStubSpec().className).toEqual "Book"
      (expect commandGroup[1] instanceof AddEdit).toBe true
      (expect commandGroup[2] instanceof RemoveUse).toBe true
      (expect commandGroup[2].getSymbol().getName()).toEqual "book"

  describe "when given an InnerClassSuggestion", ->

    model = undefined
    commandGroup = undefined

    beforeEach =>
      model = new ExampleModel()
      commandCreator = new CommandCreator()
      suggestion = new InnerClassSuggestion \
        (new Symbol TEST_FILE, "InnerClass", (new Range [4, 13], [4, 23]), "Class"),
        (new Range [4, 2], [5, 3]), true
      commandGroup = commandCreator.createCommandGroupForSuggestion suggestion

    it "creates a command for adding the class range", ->
      (expect commandGroup.length).toBe 1
      (expect commandGroup[0] instanceof AddClassRange).toBe true
      (expect commandGroup[0].getClassRange().getRange()).toEqual \
        new Range [4, 2], [5, 3]

  describe "when given extension decisions", ->

    describe "when given a ControlStructureExtension", ->

      describe "if the decision was accepted", ->

        model = undefined
        commandGroup = undefined
        beforeEach =>
          model = new ExampleModel()
          commandCreator = new CommandCreator()
          decision = new ExtensionDecision \
            (new ControlCrossingEvent()),
            (new ControlStructureExtension undefined,
              [(new Range [0, 2], [0, 3]), new Range [1, 4], [1, 9]]),
            true
          commandGroup = commandCreator.createCommandGroupForExtensionDecision decision

        it "creates a command group with the range additions", ->
          (expect commandGroup.length).toBe 3
          (expect commandGroup[1] instanceof AddRange).toBe true
          (expect commandGroup[2] instanceof AddRange).toBe true

      describe "if the decision was rejected", ->

        model = undefined
        commandGroup = undefined
        beforeEach =>
          model = new ExampleModel()
          commandCreator = new CommandCreator()
          decision = new ExtensionDecision \
            (new ControlCrossingEvent()),
            (new ControlStructureExtension undefined,
              [(new Range [0, 2], [0, 3]), new Range [1, 4], [1, 9]]),
            false
          commandGroup = commandCreator.createCommandGroupForExtensionDecision decision

        it "creates a command group with just an archived event", ->
          (expect commandGroup.length).toBe 1
          (expect commandGroup[0] instanceof ArchiveEvent).toBe true

    describe "when given a decision for a MediatingUseExtension", ->

      model = undefined
      commandGroup = undefined
      testFile = undefined
      commandCreator = undefined
      beforeEach =>
        model = new ExampleModel()
        commandCreator = new CommandCreator()
        testFile = new File "path", "file_name"

      it "on acceptance, creates a command group with a line addition", ->
        decision = new ExtensionDecision \
          (new MediatingUseEvent()),
          (new MediatingUseExtension \
            (new Symbol testFile, "i", (new Range [2, 8], [2, 9]), "int"),
            (new Symbol testFile, "i", (new Range [5, 23], [5, 24]), "int")),
          true
        commandGroup = commandCreator.createCommandGroupForExtensionDecision decision
        (expect commandGroup.length).toBe 2
        (expect commandGroup[1] instanceof AddLineForRange).toBe true
        (expect commandGroup[1].getRange()).toEqual new Range [5, 23], [5, 24]

      it "on rejection, creates a command group an event archiving command", ->
        decision = new ExtensionDecision \
          (new MediatingUseEvent()),
          (new MediatingUseExtension \
            (new Symbol testFile, "i", (new Range [2, 8], [2, 9]), "int"),
            (new Symbol testFile, "i", (new Range [5, 23], [5, 24]), "int")),
          false
        commandGroup = commandCreator.createCommandGroupForExtensionDecision decision
        (expect commandGroup.length).toBe 1
        (expect commandGroup[0] instanceof ArchiveEvent).toBe true

    describe "when given a decision for MethodThrowsExtension", ->

      model = undefined
      commandGroup = undefined
      testFile = undefined
      commandCreator = undefined
      beforeEach =>
        model = new ExampleModel()
        commandCreator = new CommandCreator()
        testFile = new File "path", "file_name"

      it "on acceptance, creates a command group with a line addition", ->
        decision = new ExtensionDecision \
          (new MethodThrowsEvent()),
          (new MethodThrowsExtension "IOException",
            (new Range [2, 25], [2, 31]), (new Range [2, 32], [2, 43]),
            (new Range [2, 2], [2, 45]), (new Range [3, 4], [3, 8]), undefined),
          true
        commandGroup = commandCreator.createCommandGroupForExtensionDecision decision
        (expect commandGroup.length).toBe 2
        (expect commandGroup[1] instanceof AddThrows).toBe true
        (expect commandGroup[1].getThrowableName()).toEqual "IOException"

      it "on rejection, creates a command group an event archiving command", ->
        decision = new ExtensionDecision \
          (new MethodThrowsEvent()),
          (new MethodThrowsExtension "IOException",
            (new Range [2, 25], [2, 31]), (new Range [2, 32], [2, 43]),
            (new Range [2, 2], [2, 45]), (new Range [3, 4], [3, 8]), undefined),
          false
        commandGroup = commandCreator.createCommandGroupForExtensionDecision decision
        (expect commandGroup.length).toBe 1
        (expect commandGroup[0] instanceof ArchiveEvent).toBe true
