# 'use babel';

{Examplify} = require '../lib/examplify'
{CodeViewer} = require '../lib/code_viewer'

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.


describe 'Examplify', () ->

  it 'calls \'em like it sees \'em', () ->
    expect(true).toBe true
    expect(false).toBe false


describe 'CodeViewer', () ->

  it 'sees things for what they are', () ->
    codeViewer = new CodeViewer()
    expect(codeViewer.returnTwo()).toBe 2


"""
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
*/
"""
