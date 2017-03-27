{ ImportSuggestion } = require "../suggester/import-suggester"
{ DefinitionSuggestion } = require "../suggester/definition-suggester"
{ PrimitiveValueSuggestion } = require "../suggester/primitive-value-suggester"
{ DeclarationSuggestion } = require "../suggester/declaration-suggester"
{ InstanceStubSuggestion } = require "../suggester/instance-stub-suggester"
{ ExtensionDecision } = require "../extender/extension-decision"
{ ControlStructureExtension } = require "../extender/control-structure-extender"
{ Replacement } = require "../edit/replacement"
{ Declaration } = require "../edit/declaration"


module.exports.Reverter = class Reverter

  revert: (model, command) ->

    if command instanceof DefinitionSuggestion
      # XXX: For now, we just delete the first active range with the same
      # range as the definition's line that we can find.  Note that this
      # might break if the same range is added twice.
      codeBuffer = model.getCodeBuffer()
      symbolRange = command.getSymbol().getRange()
      startRowRange = codeBuffer.rangeForRow symbolRange.start.row
      endRowRange = codeBuffer.rangeForRow symbolRange.end.row
      definitionRange = startRowRange.union endRowRange
      model.getRangeSet().getActiveRanges().remove definitionRange
