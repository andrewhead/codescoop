{ ImportSuggestion } = require "../suggester/import-suggester"
{ DefinitionSuggestion } = require "../suggester/definition-suggester"
{ PrimitiveValueSuggestion } = require "../suggester/primitive-value-suggester"
{ DeclarationSuggestion } = require "../suggester/declaration-suggester"
{ InstanceStubSuggestion } = require "../suggester/instance-stub-suggester"
{ InnerClassSuggestion } = require "../suggester/inner-class-suggester"
{ ExtensionDecision } = require "../extender/extension-decision"
{ ControlStructureExtension } = require "../extender/control-structure-extender"
{ MediatingUseExtension } = require "../extender/mediating-use-extender"

{ ClassRange } = require "../model/range-set"
{ Replacement } = require "../edit/replacement"
{ Declaration } = require "../edit/declaration"

{ AddLineForRange } = require "../command/add-line-for-range"
{ AddRange } = require "../command/add-range"
{ AddClassRange } = require "../command/add-class-range"
{ AddImport } = require "../command/add-import"
{ AddEdit } = require "../command/add-edit"
{ RemoveUse } = require "../command/remove-use"
{ AddDeclaration } = require "../command/add-declaration"
{ AddStubSpec } = require "../command/add-stub-spec"
{ ArchiveEvent } = require "../command/archive-event"


module.exports.CommandCreator = class CommandCreator

  # Return a group of commands that specify everything needed to revert the fix.
  # This usually means references the commandCreator creates.
  createCommandGroupForSuggestion: (suggestion) ->

    commandGroup = []

    if suggestion instanceof DefinitionSuggestion
      commandGroup.push new AddLineForRange suggestion.getSymbol().getRange()

    else if suggestion instanceof ImportSuggestion
      commandGroup.push new AddImport suggestion.getImport()

    # For primitive values, replace the symbol with a concrete value and then
    # mark the symbol as no longer an undefined use
    else if suggestion instanceof PrimitiveValueSuggestion
      edit = new Replacement suggestion.getSymbol(), suggestion.getValueString()
      commandGroup.push new AddEdit edit
      commandGroup.push new RemoveUse suggestion.getSymbol()

    else if suggestion instanceof DeclarationSuggestion
      symbol = suggestion.getSymbol()
      declaration = new Declaration symbol.getName(), symbol.getType()
      commandGroup.push new AddDeclaration declaration

    # For stubs of instances, add a stub spec that can be printed as part of
    # the snippet.  Replace the symbol with an instantiation of the stub.  Then
    # Mark the undefined use as resolved
    else if suggestion instanceof InstanceStubSuggestion
      commandGroup.push new AddStubSpec suggestion.getStubSpec()
      commandGroup.push new AddEdit new Replacement \
        suggestion.getSymbol(), "(new #{suggestion.getStubSpec().getClassName()}())"
      commandGroup.push new RemoveUse suggestion.getSymbol()

    else if suggestion instanceof InnerClassSuggestion
      commandGroup.push new AddClassRange \
        new ClassRange suggestion.getRange(),
          suggestion.getSymbol(),suggestion.isStatic()

    commandGroup

  createCommandGroupForExtensionDecision: (extensionDecision) ->

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
