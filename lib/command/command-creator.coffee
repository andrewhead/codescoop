{ ImportSuggestion } = require "../suggester/import-suggester"
{ DefinitionSuggestion } = require "../suggester/definition-suggester"
{ PrimitiveValueSuggestion } = require "../suggester/primitive-value-suggester"
{ DeclarationSuggestion } = require "../suggester/declaration-suggester"
{ InstanceStubSuggestion } = require "../suggester/instance-stub-suggester"
{ LocalMethodSuggestion } = require "../suggester/local-method-suggester"
{ InnerClassSuggestion } = require "../suggester/inner-class-suggester"
{ ExtensionDecision } = require "../extender/extension-decision"
{ ControlStructureExtension } = require "../extender/control-structure-extender"
{ MediatingUseExtension } = require "../extender/mediating-use-extender"
{ MethodThrowsExtension } = require "../extender/method-throws-extender"

{ MethodRange } = require "../model/range-set"
{ ClassRange } = require "../model/range-set"
{ Replacement } = require "../edit/replacement"
{ Declaration } = require "../edit/declaration"

{ AddLineForRange } = require "../command/add-line-for-range"
{ AddRange } = require "../command/add-range"
{ AddMethodRange } = require "../command/add-method-range"
{ AddClassRange } = require "../command/add-class-range"
{ AddImport } = require "../command/add-import"
{ AddThrows } = require "../command/add-throws"
{ AddEdit } = require "../command/add-edit"
{ RemoveUse } = require "../command/remove-use"
{ AddDeclaration } = require "../command/add-declaration"
{ AddStubSpec } = require "../command/add-stub-spec"
{ ArchiveEvent } = require "../command/archive-event"


# Each of the createCommand* functions returns a group of commands that specify
# everything needed to revert the fix.  Each function is built to map from
# a different kind of user suggestion or choice to a command.
module.exports.CommandCreator = class CommandCreator

  createCommandGroupForChosenRange: (range) ->
    commandGroup = []
    commandGroup.push new AddRange range
    commandGroup

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

    else if suggestion instanceof LocalMethodSuggestion
      commandGroup.push new AddMethodRange \
        new MethodRange suggestion.getRange(),
          suggestion.getSymbol(), suggestion.isStatic()

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

      else if extension instanceof MethodThrowsExtension
        commandGroup.push new AddThrows extension.getThrowableName()

    commandGroup
