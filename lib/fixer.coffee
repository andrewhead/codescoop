{ SymbolSuggestion } = require './suggester/definition-suggester'
{ PrimitiveValueSuggestion } = require "./suggester/primitive-value-suggester"
{ DeclarationSuggestion } = require "./suggester/declaration-suggester"
{ InstanceStubSuggestion } = require "./suggester/instance-stub-suggester"
{ Replacement } = require "./edit/replacement"
{ Declaration } = require "./edit/declaration"


module.exports.Fixer = class Fixer

  # Make sure a symbol is no longer marked as a "use" in the model, to hide
  # definition errors if the use has been defined some other way
  _removeUse: (model, removableUse) ->
    uses = model.getSymbols().getUses()
    useIndex = 0
    for use in uses
      if use.equals removableUse
        uses.splice useIndex, 1
        break
      useIndex += 1

  apply: (model, suggestion) ->

    # TODO: eventually this should add the smallest range that defines
    # the symbol, but right now it adds lines
    if suggestion instanceof SymbolSuggestion
      codeBuffer = model.getCodeBuffer()
      symbolRange = suggestion.getSymbol().getRange()
      startRowRange = codeBuffer.rangeForRow symbolRange.start.row
      endRowRange = codeBuffer.rangeForRow symbolRange.end.row
      rangeUnion = startRowRange.union endRowRange
      model.getRangeSet().getActiveRanges().push rangeUnion

    # For primitive values, replace the symbol with a concrete value and then
    # mark the symbol as no longer an undefined use
    else if suggestion instanceof PrimitiveValueSuggestion
      edit = new Replacement suggestion.getSymbol(), suggestion.getValueString()
      model.getEdits().push edit
      @_removeUse model, suggestion.getSymbol()

    else if suggestion instanceof DeclarationSuggestion
      symbol = suggestion.getSymbol()
      declaration = new Declaration symbol.getName(), symbol.getType()
      model.getAuxiliaryDeclarations().push declaration

    else if suggestion instanceof InstanceStubSuggestion

      symbol = suggestion.getSymbol()
      stubSpec = suggestion.getStubSpec()

      # Add a stub spec that can be printed as part of the snippet
      model.getStubSpecs().push stubSpec

      # Replace the symbol with an instantiation of the stub
      edit = new Replacement suggestion.getSymbol(),
        "(new #{stubSpec.getClassName()}())"
      model.getEdits().push edit

      # Mark the undefined use as resolved
      @_removeUse model, symbol
