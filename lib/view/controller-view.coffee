{ ExampleModelState, ExampleModelProperty } = require "../model/example-model"
{ PACKAGE_PATH } = require "../config/paths"
$ = require 'jquery'
log = require "examplify-log"


module.exports.ControllerView = class ControllerView extends $

  constructor: (controller, model, exampleEditor) ->
    @controller = controller
    @model = model
    @exampleEditor = exampleEditor

    element = $ "<div></div>"
      .addClass "controller"

    # Make a button for running the chosen agent
    @printButton = $ "<button></button>"
      .attr "id", "print-symbol-button"
      .attr "disabled", (exampleEditor.getSelectedText().length == 0)
      .append @_makeIcon "quote", "Print"
      .click =>
        log.debug "Printing out a variable",
          { selection: exampleEditor.getSelectedBufferRange() }
        symbolName = exampleEditor.getSelectedText()
        controller.addPrintedSymbol symbolName
      .appendTo element

    @undoButton = $ "<button></button>"
      .attr "id", "undo-button"
      .attr "disabled", (controller.getCommandStack().getHeight() == 0)
      .append @_makeIcon "reply", "Undo"
      .click =>
        log.debug "Button press for undo"
        controller.undo()
      .appendTo element

    @runButton = $ "<button></button>"
      .attr "id", "run-button"
      .attr "disabled", (model.getState() == ExampleModelState.ANALYSIS)
      .append @_makeIcon "diff-renamed", "Run"
      .click =>
        atom.commands.dispatch (atom.views.getView exampleEditor), "script:run"
      .appendTo element

    # Enable the undo button based on whether there are commands on the stack
    controller.getCommandStack().addListener {
      onStackChanged: (stack) => @undoButton.attr "disabled", (stack.getHeight() == 0)
    }

    # Enable the print button based on whether a selection has been made
    exampleEditor.onDidChangeSelectionRange (event) =>
      newRange = event.newBufferRange
      @printButton.attr "disabled", (newRange.start.isEqual newRange.end)

    model.addObserver {
      onPropertyChanged: (target, propertyName, oldValue, newValue) =>
        if propertyName == ExampleModelProperty.STATE
          @_updateRunButton()
    }
    atom.workspace.onDidChangeActivePane (@_updateRunButton.bind @)

    @.extend @, element

  _updateRunButton: ->
    @runButton.attr "disabled",
      ((@model.getState() == ExampleModelState.ANALYSIS) or
       (atom.workspace.getActiveTextEditor() != @exampleEditor))

  _makeIcon: (iconName, label)->
    span = $ "<span></span>"
      .addClass "icon"
      .addClass "icon-#{iconName}"
    label = $ "<p></p>"
      .addClass "action_label"
      .text label
    # We return HTML instead of the object based on this recommended hack:
    # https://stackoverflow.com/questions/3642035/
    $ "<div></div>"
      .append span
      .append label
      .html()

  getNode: ->
    @[0]
