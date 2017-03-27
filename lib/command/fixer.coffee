{ ImportSuggestion } = require "../suggester/import-suggester"
{ DefinitionSuggestion } = require "../suggester/definition-suggester"
{ PrimitiveValueSuggestion } = require "../suggester/primitive-value-suggester"
{ DeclarationSuggestion } = require "../suggester/declaration-suggester"
{ InstanceStubSuggestion } = require "../suggester/instance-stub-suggester"
{ ExtensionDecision } = require "../extender/extension-decision"
{ ControlStructureExtension } = require "../extender/control-structure-extender"
{ Replacement } = require "../edit/replacement"
{ Declaration } = require "../edit/declaration"

{ AddLineForRange } = require "../command/add-line-for-range"
{ AddRange } = require "../command/add-range"
{ AddImport } = require "../command/add-import"
{ AddEdit } = require "../command/add-edit"
{ RemoveUse } = require "../command/remove-use"
{ AddDeclaration } = require "../command/add-declaration"
{ AddStubSpec } = require "../command/add-stub-spec"
{ ArchiveEvent } = require "../command/archive-event"


module.exports.Fixer = class Fixer

  # Make sure a symbol is no longer marked as a "use" in the model, to hide
  # definition errors if the use has been defined some other way
  _removeUse: (model, removableUse) ->


  # After applying the fix, the fixer should return a group of commands that
  # specify everything needed to revert the fix.  This usually means references
  # to any objects that the fixer creates and adds to the model.
  apply: (model, update) ->

    commandGroup = []

    if update instanceof DefinitionSuggestion
      commandGroup.push new AddLineForRange update.getSymbol().getRange()

    else if update instanceof ImportSuggestion
      commandGroup.push new AddImport update.getImport()

    # For primitive values, replace the symbol with a concrete value and then
    # mark the symbol as no longer an undefined use
    else if update instanceof PrimitiveValueSuggestion
      edit = new Replacement update.getSymbol(), update.getValueString()
      commandGroup.push new AddEdit edit
      commandGroup.push new RemoveUse update.getSymbol()

    else if update instanceof DeclarationSuggestion
      symbol = update.getSymbol()
      declaration = new Declaration symbol.getName(), symbol.getType()
      commandGroup.push new AddDeclaration declaration

    else if update instanceof InstanceStubSuggestion

      # Add a stub spec that can be printed as part of the snippet
      commandGroup.push new AddStubSpec update.getStubSpec()

      # Replace the symbol with an instantiation of the stub
      commandGroup.push new AddEdit new Replacement \
        update.getSymbol(), "(new #{update.getStubSpec().getClassName()}())"

      # Mark the undefined use as resolved
      commandGroup.push new RemoveUse update.getSymbol()

    else if update instanceof ExtensionDecision
      extensionCommandGroup = @_applyExtensionDecision model, update
      commandGroup = commandGroup.concat extensionCommandGroup

    for command in commandGroup
      command.apply model

    commandGroup

  _applyExtensionDecision: (model, extensionDecision) ->

    commandGroup = []

    # Regardless of whether the extension was accepted, store a record
    # that the event has been addressed
    commandGroup.push new ArchiveEvent extensionDecision.getEvent()

    # Don't apply the fix from the extension if it wasn't accepted
    if extensionDecision.getDecision()
      extension = extensionDecision.getExtension()
      if extension instanceof ControlStructureExtension
        for range in extension.getRanges()
          commandGroup.push new AddRange range

    commandGroup
