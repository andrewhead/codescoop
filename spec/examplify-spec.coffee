{ Range } = require 'atom'
{ MainController } = require '../lib/examplify'
$ = require 'jquery'


_makeCodeEditor = =>
  codeEditor = atom.workspace.buildTextEditor()
  codeEditor.setText [
    "Line 1"
    "Line 2"
    "Line 3"
    "Line 4"
    ].join '\n'
  codeEditor


describe 'MainController', () ->

  it 'updates the line set to the selected lines when invoked', ->

    codeEditor = _makeCodeEditor()
    exampleEditor = atom.workspace.buildTextEditor()

    # Remember that while the range specifies line 1, this actually corresponds
    # to line 2 as it appears in the text editor
    selectedRange = new Range [1, 0], [1, 2]
    selection = codeEditor.addSelectionForBufferRange selectedRange

    mainController = new MainController codeEditor, exampleEditor
    (expect mainController.getLineSet().getActiveLineNumbers()).toEqual [2]

  it 'highlights lines on the screen when invoked with a selection', ->

    codeEditor = _makeCodeEditor()
    exampleEditor = atom.workspace.buildTextEditor()

    # Add some lines to the code editor that can be selected
    codeEditorView = atom.views.getView(codeEditor)
    ($ (codeEditorView.querySelector 'div.lines')).append $(
      $("<div class=line data-screen-row=0>Line 1</div>" +
        "<div class=line data-screen-row=1>Line 2</div>" +
        "<div class=line data-screen-row=2>Line 3</div>" +
        "<div class=line data-screen-row=3>Line 4</div>"
      )
    )
    
    selectedRange = new Range [1, 0], [1, 2]
    selection = codeEditor.addSelectionForBufferRange selectedRange
    mainController = new MainController codeEditor, exampleEditor

    # Check to see that one of the lines was activated based on selectedRange
    activeLines = ($ (codeEditorView.querySelectorAll 'div.line.active'))
    (expect activeLines.length).toBe 1


###
beforeEach(() => {
  workspaceElement = atom.views.getView(atom.workspace);
  activationPromise = atom.packages.activatePackage('examplify');
});

describe('when the examplify:toggle event is triggered', () => {
  it('hides and shows the modal panel', () => {
    // Before the activation event the view is not on the DOM, and no panel
    // has been created
    expect(workspaceElement.querySelector('.examplify')).not.toExist();

    // This is an activation event, triggering it will cause the package to be
    // activated.
    atom.commands.dispatch(workspaceElement, 'examplify:toggle');

    waitsForPromise(() => {
      return activationPromise;
    });

    runs(() => {
      expect(workspaceElement.querySelector('.examplify')).toExist();

      let examplifyElement = workspaceElement.querySelector('.examplify');
      expect(examplifyElement).toExist();

      let examplifyPanel = atom.workspace.panelForItem(examplifyElement);
      expect(examplifyPanel.isVisible()).toBe(true);
      atom.commands.dispatch(workspaceElement, 'examplify:toggle');
      expect(examplifyPanel.isVisible()).toBe(false);
    });
  });

  it('hides and shows the view', () => {
    // This test shows you an integration test testing at the view level.

    // Attaching the workspaceElement to the DOM is required to allow the
    // `toBeVisible()` matchers to work. Anything testing visibility or focus
    // requires that the workspaceElement is on the DOM. Tests that attach the
    // workspaceElement to the DOM are generally slower than those off DOM.
    jasmine.attachToDOM(workspaceElement);

    expect(workspaceElement.querySelector('.examplify')).not.toExist();

    // This is an activation event, triggering it causes the package to be
    // activated.
    atom.commands.dispatch(workspaceElement, 'examplify:toggle');

    waitsForPromise(() => {
      return activationPromise;
    });

    runs(() => {
      // Now we can test for view visibility
      let examplifyElement = workspaceElement.querySelector('.examplify');
      expect(examplifyElement).toBeVisible();
      atom.commands.dispatch(workspaceElement, 'examplify:toggle');
      expect(examplifyElement).not.toBeVisible();
    });
  });
});
###
