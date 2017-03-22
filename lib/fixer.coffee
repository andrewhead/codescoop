{ ImportSuggestion } = require "./suggester/import-suggester"
{ SymbolSuggestion } = require "./suggester/definition-suggester"
{ PrimitiveValueSuggestion } = require "./suggester/primitive-value-suggester"
{ DeclarationSuggestion } = require "./suggester/declaration-suggester"
{ InstanceStubSuggestion } = require "./suggester/instance-stub-suggester"
{ ControlStructureExtension } = require "./extender/control-structure-extender"
{ Replacement } = require "./edit/replacement"
{ Declaration } = require "./edit/declaration"


module.exports.Fixer = class Fixer

  # Make sure a symbol is no longer marked as a "use" in the model, to hide
  # definition errors if the use has been defined some other way
  _removeUse: (model, removableUse) ->
    uses = model.getSymbols().getVariableUses()
    useIndex = 0
    for use in uses
      if use.equals removableUse
        uses.splice useIndex, 1
        break
      useIndex += 1

  apply: (model, update) ->

    # TODO: eventually this should add the smallest range that defines
    # the symbol, but right now it adds lines
    if update instanceof SymbolSuggestion
      codeBuffer = model.getCodeBuffer()
      symbolRange = update.getSymbol().getRange()
      startRowRange = codeBuffer.rangeForRow symbolRange.start.row
      endRowRange = codeBuffer.rangeForRow symbolRange.end.row
      rangeUnion = startRowRange.union endRowRange
      model.getRangeSet().getActiveRanges().push rangeUnion

    else if update instanceof ImportSuggestion
      model.getImports().push update.getImport()

    # For primitive values, replace the symbol with a concrete value and then
    # mark the symbol as no longer an undefined use
    else if update instanceof PrimitiveValueSuggestion
      edit = new Replacement update.getSymbol(), update.getValueString()
      model.getEdits().push edit
      @_removeUse model, update.getSymbol()

    else if update instanceof DeclarationSuggestion
      symbol = update.getSymbol()
      declaration = new Declaration symbol.getName(), symbol.getType()
      model.getAuxiliaryDeclarations().push declaration

    else if update instanceof InstanceStubSuggestion

      symbol = update.getSymbol()
      stubSpec = update.getStubSpec()

      # Add a stub spec that can be printed as part of the snippet
      model.getStubSpecs().push stubSpec

      # Replace the symbol with an instantiation of the stub
      edit = new Replacement update.getSymbol(),
        "(new #{stubSpec.getClassName()}())"
      model.getEdits().push edit

      # Mark the undefined use as resolved
      @_removeUse model, symbol

    else if update instanceof ControlStructureExtension
      activeRanges = model.getRangeSet().getActiveRanges()
      for range in update.getRanges()
        activeRanges.push range
