{ Fixer } = require "../lib/fixer"
{ ExampleModel } = require "../lib/model/example-model"
{ Symbol, SymbolSet, File } = require "../lib/model/symbol-set"
{ Range, RangeSet } = require "../lib/model/range-set"
{ StubSpec } = require "../lib/model/stub"
{ Import } = require "../lib/model/import"
{ Replacement } = require "../lib/edit/replacement"
{ Declaration } = require "../lib/edit/declaration"

{ ImportSuggestion } = require "../lib/suggester/import-suggester"
{ DefinitionSuggestion } = require "../lib/suggester/definition-suggester"
{ PrimitiveValueSuggestion } = require "../lib/suggester/primitive-value-suggester"
{ InstanceStubSuggestion } = require '../lib/suggester/instance-stub-suggester'
{ DeclarationSuggestion } = require "../lib/suggester/declaration-suggester"
{ ControlStructureExtension } = require "../lib/extender/control-structure-extender"


_rangeInRanges = (range, ranges) =>
  for otherRange in ranges
    if range.isEqual otherRange
      return true
  false


describe "Fixer", ->

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
  fixer = new Fixer()

  it "adds a range that includes a symbol of a DefinitionSuggestion", ->
    model = _makeModel()
    suggestion = new DefinitionSuggestion \
      new Symbol TEST_FILE, "i", new Range [0, 4], [0, 5]
    fixer.apply model, suggestion

    activeRanges = model.getRangeSet().getActiveRanges()
    activeRangeFound = false
    for range in activeRanges
      if range.containsRange suggestion.getSymbol().getRange()
        activeRangeFound = true
    (expect activeRangeFound).toBe true

  describe "when handling an ImportSuggestion", ->

    codeBuffer = atom.workspace.buildTextEditor().getBuffer()
    codeBuffer.setText [
      "import org.ImportedClass;"
      "public class Book {}"
    ].join "\n"
    model = new ExampleModel codeBuffer

    it "adds an import range corresponding to the line the import appears on", ->

      suggestion = new ImportSuggestion \
        new Import "org.ImportedClass", new Range [0, 7], [0, 24]
      fixer.apply model, suggestion

      # Check the set of active ranges for at least one that includes the
      # entire line that the import occurred on
      imports = model.getImports()
      (expect imports.length).toBe 1
      (expect imports[0].getName()).toEqual "org.ImportedClass"

  describe "when handling a PrimitiveValueSuggestion", ->

    model = _makeModel()
    model.getSymbols().setVariableUses [
      new Symbol TEST_FILE, "i", new Range [1, 8], [1, 9]
      new Symbol TEST_FILE, "i", new Range [1, 12], [1, 13]
    ]
    suggestion = new PrimitiveValueSuggestion \
      (new Symbol TEST_FILE, "i", new Range [1, 8], [1, 9]), "15"
    fixer.apply model, suggestion

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

  describe "when applying a DeclarationSuggestion", ->

    it "adds an extra declaration to the model", ->
      model = _makeModel()
      (expect model.getAuxiliaryDeclarations().length).toBe 0
      suggestion = new DeclarationSuggestion \
        "i", "int", new Symbol TEST_FILE, "i", (new Range [0, 4], [0, 5]), "int"
      fixer.apply model, suggestion
      declarations = model.getAuxiliaryDeclarations()
      (expect declarations.length).toBe 1
      declaration = declarations[0]
      (expect declaration instanceof Declaration).toBe true
      (expect declaration.getName()).toEqual "i"
      (expect declaration.getType()).toEqual "int"

  describe "when applying an InstanceStubSuggestion", ->

    model = _makeModel()
    model.getSymbols().setVariableUses [
      new Symbol TEST_FILE, "book", (new Range [4, 11], [4, 15]), "Book"
    ]
    (expect model.getStubSpecs().length).toBe 0
    suggestion = new InstanceStubSuggestion \
      (new Symbol TEST_FILE, "book", (new Range [4, 11], [4, 15]), "Book"),
      (new StubSpec "Book")
    fixer.apply model, suggestion

    it "adds the stub spec to the model", ->
      stubSpecs = model.getStubSpecs()
      (expect stubSpecs.length).toBe 1
      (expect stubSpecs[0].className).toBe "Book"

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

  describe "when applying a ControlStructureExtension", ->

    it "adds the structure's ranges to the model", ->
      model = _makeModel()
      extension = new ControlStructureExtension undefined,
        [(new Range [0, 2], [0, 3]), new Range [1, 4], [1, 9]], undefined
      fixer.apply model, extension
      activeRanges = model.getRangeSet().getActiveRanges()
      (expect _rangeInRanges (new Range [0, 2], [0, 3]), activeRanges).toBe true
      (expect _rangeInRanges (new Range [1, 4], [1, 9]), activeRanges).toBe true
