{ ExampleModelState, ExampleModelProperty } = require "../model/example-model"
{ PACKAGE_PATH } = require "../config/paths"
$ = require 'jquery'
log = require "examplify-log"


module.exports.ControllerView = class ControllerView extends $

  constructor: (pluginController) ->

    @pluginController = pluginController
    @pluginController.addInitListener @

    element = $ "<div></div>"
      .addClass "controller"

    @scoopButton = $ "<button></button>"
      .attr "id", "scoop-button"
      .attr "disabled", true
      .append @_makeIcon "paintcan", "Scoop"
      .click =>
        @scoopButton.data 'clicked', true
        atom.commands.dispatch \
          (atom.views.getView atom.workspace.getActiveTextEditor()),
          "examplify:make-example-code"
      .appendTo element

    atom.workspace.getActiveTextEditor().onDidChangeSelectionRange (event) =>
      newRange = event.newBufferRange
      @scoopButton.attr "disabled", (
        (@scoopButton.data 'clicked') or
        newRange.start.isEqual newRange.end)

    """
    @printButton = $ "<button></button>"
      .attr "id", "print-symbol-button"
      .attr "disabled", true
      .append @_makeIcon "quote", "Print"
      .appendTo element
    """

    @undoButton = $ "<button></button>"
      .attr "id", "undo-button"
      .attr "disabled", true
      .append @_makeIcon "mail-reply", "Undo"
      .appendTo element

    # Make a button for running the chosen agent
    @runButton = $ "<button></button>"
      .attr "id", "run-button"
      .attr "disabled", true
      .append @_makeIcon "diff-renamed", "Run"
      .appendTo element

    # Make a button for running the chosen agent
    @resetButton = $ "<button></button>"
      .attr "id", "reset-button"
      .attr "disabled", true
      .append @_makeIcon "sync", "Reset"
      .appendTo element

    @helpButton = $ "<button></button>"
      .attr "id", "help-button"
      .append @_makeIcon "info", "Hide Help"
      .click =>
        helpPanel = $ "div.help"
        console.log helpPanel.css "display"
        if (helpPanel.css "display") != "none"
          helpPanel.css "display", "none"
          @helpButton.html @_makeIcon "info", "Show Help"
        else
          helpPanel.css "display", "block"
          @helpButton.html @_makeIcon "info", "Hide Help"
      .appendTo element

    @.extend @, element

  onPluginInitDone: (pluginController) ->

    exampleEditor = pluginController.exampleEditor
    exampleController = pluginController.exampleController
    model = pluginController.exampleModel

    # Disable the "scoop" button
    @scoopButton.attr "disabled", true

    # Enable run button only when the example editor is selected, and
    # when analysis isn't going on.
    model.addObserver {
      onPropertyChanged: (target, propertyName, oldValue, newValue) =>
        if propertyName == ExampleModelProperty.STATE
          @_updateRunButton model, exampleEditor
    }
    atom.workspace.onDidChangeActivePane =>
      @_updateRunButton.bind model, exampleEditor

    # When the run button is clicked, show a message that running is unsupported.
    @runButton.click =>
      atom.notifications.addInfo \
        "Compiling and running is disabled for the online demo. " +
        "Check out the repository for the full prototype at " +
        "https://github.com/andrewhead/codescoop.",
        { dismissable: true, icon: "diff-renamed" }
      # atom.commands.dispatch (atom.views.getView exampleEditor), "script:run"

    # Enable the run-button: people should be able to test the program now!
    @runButton.attr "disabled", false

    # Enable the print button whenever a selection is made in the example
    # editor.
    """
    exampleEditor.onDidChangeSelectionRange (event) =>
      newRange = event.newBufferRange
      @printButton.attr "disabled", (newRange.start.isEqual newRange.end)
    """

    # When the print button is clicked, add a print statement
    """
    @printButton.click =>
      log.debug "Printing out a variable",
        { selection: exampleEditor.getSelectedBufferRange() }
      symbolName = exampleEditor.getSelectedText()
      exampleController.addPrintedSymbol symbolName
    """

    # Enable the undo button based on whether there are commands on the stack
    exampleController.getCommandStack().addListener {
      onStackChanged: (stack) =>
        @undoButton.attr "disabled", (stack.getHeight() == 0)
    }

    # Undo an action when the undo button is clicked
    @undoButton.click =>
      log.debug "Button press for undo"
      exampleController.undo()

    @resetButton
      .attr "disabled", false
      .click =>
        atom.commands.dispatch \
          (atom.views.getView exampleEditor), "examplify:reset"

  _updateRunButton: (model, exampleEditor) ->
    @runButton.attr "disabled",
      ((model.getState() == ExampleModelState.ANALYSIS) or
       (atom.workspace.getActiveTextEditor() != exampleEditor))

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
