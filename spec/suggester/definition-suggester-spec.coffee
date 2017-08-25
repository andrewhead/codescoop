{ MissingDefinitionError } = require "../../lib/error/missing-definition"
{ DefinitionSuggester } = require "../../lib/suggester/definition-suggester"
{ DefinitionSuggestion } = require "../../lib/suggester/definition-suggester"
{ Symbol, SymbolSet, createSymbol, createSymbolText } = require "../../lib/model/symbol-set"
{ Range, RangeSet } = require "../../lib/model/range-set"
{ parse } = require "../../lib/analysis/parse-tree"
{ ExampleModel } = require "../../lib/model/example-model"
{ SymbolTable } = require "../../lib/model/symbol-table"

describe "DefinitionSuggester", ->

  describe "when used in flat scopes", ->

    # This is based on the following code example
    # public class Example {
    #
    #   public doWork() {
    #     // Even though this is a definition of k, it shouldn't be a
    #     // suggested definition for k in the main (it's out of scope)
    #     int k = 2;
    #   }
    #
    #   public static void main(String [] args) {
    #     int i = 1;
    #     int j = i + 1;
    #     int k = j + 1;  // j has one def above
    #     i = 2;
    #     i = 3;
    #     System.out.println(i);  // i has two defs above
    #     System.out.println(k);  // k has only one def
    #   }
    # }
    suggester = new DefinitionSuggester()

    kUse = createSymbol "path", "filename", "k", [5, 8], [5, 9], "int"
    iUse = createSymbol "path", "filename", "i", [9, 8], [9, 9], "int"
    jUse = createSymbol "path", "filename", "j", [10, 8], [10, 9], "int"
    iUse2 = createSymbol "path", "filename", "i", [10, 12], [10, 13], "int"
    kUse2 = createSymbol "path", "filename", "k", [11, 8], [11, 9], "int"
    jUse2 = createSymbol "path", "filename", "j", [11, 12], [11, 13], "int"
    iUse3 = createSymbol "path", "filename", "i", [14, 23], [14, 24], "int"
    kUse3 = createSymbol "path", "filename", "k", [15, 23], [15, 24], "int"

    kDef = createSymbol "path", "filename", "k", [5, 8], [5, 9], "int"
    iDef = createSymbol "path", "filename", "i", [9, 8], [9, 9], "int"
    jDef = createSymbol "path", "filename", "j", [10, 8], [10, 9], "int"
    kDef2 = createSymbol "path", "filename", "k", [11, 8], [11, 9], "int"
    iDef2 = createSymbol "path", "filename", "i", [12, 4], [12, 5], "int"
    iDef3 = createSymbol "path", "filename", "i", [13, 4], [13, 5], "int"

    symbols = new SymbolSet {
      uses: [kUse, iUse, jUse, iUse2, kUse2, jUse2, iUse3, kUse3]
      defs: [kDef, iDef, jDef, kDef2, iDef2, iDef3]
    }
    symbolTable = new SymbolTable()
    symbolTable.putDeclaration iDef, iDef.getSymbolText()
    symbolTable.putDeclaration iDef2, iDef.getSymbolText()
    symbolTable.putDeclaration iDef3, iDef.getSymbolText()
    symbolTable.putDeclaration iUse, iDef.getSymbolText()
    symbolTable.putDeclaration iUse2, iDef.getSymbolText()
    symbolTable.putDeclaration iUse3, iDef.getSymbolText()
    symbolTable.putDeclaration jDef, jDef.getSymbolText()
    symbolTable.putDeclaration jUse, jDef.getSymbolText()
    symbolTable.putDeclaration jUse2, jDef.getSymbolText()
    symbolTable.putDeclaration kDef, kDef.getSymbolText()
    symbolTable.putDeclaration kUse, kDef.getSymbolText()
    symbolTable.putDeclaration kDef2, kDef2.getSymbolText()
    symbolTable.putDeclaration kUse2, kDef2.getSymbolText()
    symbolTable.putDeclaration kUse3, kDef2.getSymbolText()

    # For testing purposes, it doesn't matter what value rangeSet has,
    # as the definition suggester only looks at existing defs, and does not
    # care about what lines are in the active set.
    rangeSet = new RangeSet()

    # Make a model that can be passed to the suggester with all data
    model = new ExampleModel undefined, rangeSet, symbols
    model.setSymbolTable symbolTable

    _indexOf = (suggestion, suggestions) =>
      i = 0
      for otherSuggestion in suggestions
        if suggestion.equals otherSuggestion
          return i
        i += 1
      false

    it "suggests a def that appears above the use", ->

      error = new MissingDefinitionError \
        createSymbol "path", "filename", "j", [11, 12], [11, 13], "int"
      suggestions = suggester.getSuggestions error, model

      suggestion = suggestions[0]
      (expect suggestions.length).toBe 1
      (expect suggestion instanceof DefinitionSuggestion).toBe true
      (expect suggestion.getSymbol()).toEqual \
        createSymbol "path", "filename", "j", [10, 8], [10, 9], "int"

    it "prioritizes defs that are closer to the use", ->

      error = new MissingDefinitionError \
        createSymbol "path", "filename", "i", [14, 23], [14, 24], "int"
      suggestions = suggester.getSuggestions error, model

      ranges = (s.getSymbol().getRange() for s in suggestions)
      (expect suggestions.length).toBe 3
      (expect ranges[0]).toEqual new Range [13, 4], [13, 5]
      (expect ranges[1]).toEqual new Range [12, 4], [12, 5]
      (expect ranges[2]).toEqual new Range [9, 8], [9, 9]

    it "only suggests a def that affects the variable in scope of the use", ->
      error = new MissingDefinitionError \
        createSymbol "path", "filename", "k", [15, 23], [15, 24], "int"
      suggestions = suggester.getSuggestions error, model
      (expect suggestions.length).toBe 1

    it "only suggests defs that are above the use", ->
      error = new MissingDefinitionError \
        createSymbol "path", "filename", "i", [10, 12], [10, 13], "int"
      suggestions = suggester.getSuggestions error, model
      (expect suggestions.length).toBe 1
      ranges = (s.getSymbol().getRange() for s in suggestions)
      (expect ranges[0]).toEqual new Range [9, 8], [9, 9]

  describe "when used with nested scopes", ->

    it "finds defs that affect the same variable from a cousin scope", ->

      # This test is based on the following code:
      # public class Example {
      #
      #   public static void main(String [] args) {
      #     int i;
      #     {
      #         i = 1;
      #     }
      #     System.out.println(i);
      #   }
      # }
      suggester = new DefinitionSuggester()
      iUse = createSymbol "path", "filename", "i", [7, 23], [7, 24], "int"
      iDef = createSymbol "path", "filename", "i", [5, 8], [5, 9], "int"
      iDeclaration = createSymbolText "i", [3, 8], [3, 9]
      uses = [ iUse ]
      defs = [ iDef ]
      symbolTable = new SymbolTable()
      symbolTable.putDeclaration iDef, iDeclaration
      symbolTable.putDeclaration iUse, iDeclaration

      # Make a model that can be passed to the suggester with all data
      model = new ExampleModel()
      model.getSymbols().getVariableUses().reset uses
      model.getSymbols().getVariableDefs().reset defs
      model.setSymbolTable symbolTable

      error = new MissingDefinitionError iUse
      suggestions = suggester.getSuggestions error, model
      (expect suggestions.length).toBe 1
      (expect suggestions[0].getSymbol().getRange()).toEqual \
        new Range [5, 8], [5, 9]

    it "finds defs in a cousin scope only before a redeclaration", ->

      # This test is based on the following example:
      # public class Example {
      #
      #   public static void main(String [] args) {
      #     int i;
      #     {
      #         i = 1;
      #         int i;  // Declares a new 'i' in this scope
      #         i = 2;  // This second definition shouldn't match the use
      #     }
      #     System.out.println(i);
      #   }
      # }
      suggester = new DefinitionSuggester()
      iUse = createSymbol "path", "filename", "i", [9, 23], [9, 24], "int"
      iDef = createSymbol "path", "filename", "i", [5, 8], [5, 9], "int"
      iDef2 = createSymbol "path", "filename", "i", [7, 8], [7, 9], "int"
      iDeclaration = createSymbolText "i", [3, 8], [3, 9]
      iDeclaration2 = createSymbolText "i", [6, 12], [6, 13]
      uses = [ iUse ]
      defs = [ iDef, iDef2 ]
      symbolTable = new SymbolTable()
      symbolTable.putDeclaration iUse, iDeclaration
      symbolTable.putDeclaration iDef, iDeclaration
      symbolTable.putDeclaration iDef2, iDeclaration2

      # Make a model that can be passed to the suggester with all data
      model = new ExampleModel()
      model.getSymbols().getVariableUses().reset uses
      model.getSymbols().getVariableDefs().reset defs
      model.setSymbolTable symbolTable

      error = new MissingDefinitionError iUse
      suggestions = suggester.getSuggestions error, model
      (expect suggestions.length).toBe 1
      (expect suggestions[0].getSymbol().getRange()).toEqual \
        new Range [5, 8], [5, 9]
