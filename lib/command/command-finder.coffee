{ ImportSuggestion } = require "../suggester/import-suggester"
{ DefinitionSuggestion } = require "../suggester/definition-suggester"
{ PrimitiveValueSuggestion } = require "../suggester/primitive-value-suggester"
{ DeclarationSuggestion } = require "../suggester/declaration-suggester"
{ InstanceStubSuggestion } = require "../suggester/instance-stub-suggester"
{ ExtensionDecision } = require "../extender/extension-decision"
{ ControlStructureExtension } = require "../extender/control-structure-extender"
{ MediatingUseExtension } = require "../extender/mediating-use-extender"
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


module.exports.CommandFinder = class CommandFinder

  # Return a group of commands that specify everything needed to revert the fix.
  # This usually means references the commandFinder creates.
  getCommandsForSuggestion: (update) ->

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

    commandGroup

  getCommandsForExtensionDecision: (extensionDecision) ->

    commandGroup = []

    # Regardless of whether the extension was accepted, store a record
    # that the event has been addressed
    commandGroup.push new ArchiveEvent extensionDecision.getEvent()

    # Don't create a fix from the extension if it wasn't accepted
    if extensionDecision.getDecision()

      extension = extensionDecision.getExtension()

      if extension instanceof ControlStructureExtension
        for range in extension.getRanges()
          commandGroup.push new AddRange range

      else if extension instanceof MediatingUseExtension
        commandGroup.push new AddLineForRange \
          extension.getMediatingUse().getRange()

    commandGroup
