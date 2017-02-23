'use babel';

import { CompositeDisposable, Range } from 'atom';
java = require('java');
fs = require('fs');
$ = require('jquery');

THIS_PACKAGE_PATH = atom.packages.resolvePackagePath('examplify');
JAVA_LIBS_DIR = THIS_PACKAGE_PATH + '/java/libs';

// Prepare the gateway to Java code for running static analysis
libs = fs.readdirSync(JAVA_LIBS_DIR);
java.classpath.push(THIS_PACKAGE_PATH + '/java');
java.classpath.push()
libs.forEach((libName) => {
  if (libName.endsWith('.jar'))
    java.classpath.push(JAVA_LIBS_DIR + '/' + libName);
});

// Sorry, you'll need to modify this for the Java home on your computer.
// I'm hard-coding it so I can do this fast locally
JAVA_HOME = "/Library/Java/JavaVirtualMachines/jdk1.7.0_67.jdk/Contents/Home";
jre_libs = fs.readdirSync(JAVA_HOME + '/jre/lib');
jre_libs.forEach((libName) => {
  if (libName.endsWith('.jar'))
    java.classpath.push(JAVA_HOME + '/jre/lib/' + libName);
});
java.classpath.push(JAVA_HOME + '/lib/tools.jar');

// Load up the Java objects we want to use
SOOT_CLASSPATH = java.classpath.join(':');
SOOT_CLASSPATH = SOOT_CLASSPATH + ':' + THIS_PACKAGE_PATH + '/java/tests/';
DataflowAnalysis = java.import("DataflowAnalysis");
SymbolAppearance = java.import("SymbolAppearance");
VariableTracer = java.import("VariableTracer");
dataflowAnalysis = undefined;

// Globals
// List of markers that can be invalidated when a new choice was made
definitionMarkers = [];
// Working set of lines that are currently being used in the example
includedLines = [];
// A Java map of values that variables hold at lines in the file under focus.
variableValues = undefined;
// The main editor in which example code is being created
examplifyEditor = undefined;


export default {

  examplifyView: null,
  modalPanel: null,
  subscriptions: null,

  getActiveFileClassname() {
    editor = atom.workspace.getActiveTextEditor();
    classname = editor.getTitle().replace(/\.java$/, '');
    return classname;
  },

  clearDefinitionMarkers(exclude) {
    for (i = 0; i < definitionMarkers.length; i++) {
      definitionMarker = definitionMarkers[i];
      if (exclude === undefined || exclude.indexOf(definitionMarker) === -1) {
        definitionMarker.destroy();
      }
    }
  },

  // Given a variable name and a line number, get a value that it was
  // defined to have when the code was run.  While this currently relies on
  // a Map loaded from Java using the node-java connector, it's reasonable
  // to expect that this could also read in a pre-written local file instead.
  getVariableValue(variableName, lineNumber) {

    sourceFilename = atom.workspace.getActiveTextEditor().getTitle();
    value = undefined;

    // Any one of the nested maps might return null if there's no value
    // for the key, so we do a null check for each layer of lookup.
    if (variableValues !== undefined) {
      lineToVariableMap = variableValues.getSync(sourceFilename);
      if (lineToVariableMap !== null) {
        variableToValueMap = lineToVariableMap.getSync(lineNumber);
        if (variableToValueMap !== null) {
          value = variableToValueMap.getSync(variableName).valueSync();
        }
      }
    }

    return value;

  },

  refreshVariableValues() {

    classname = this.getActiveFileClassname();

    // Get the path to the class to provide to the tracer
    editor = atom.workspace.getActiveTextEditor();
    path = editor.getPath();
    fileTitle = editor.getTitle();
    pathToFile = path.replace(fileTitle, '');

    // Run the whole program with a debugger and get the values of variables on
    // each line, to let us do data substitution.
    variableTracer = new VariableTracer();
    variableTracer.run(classname, pathToFile, (err, result) => {
      if (err) {
        console.error("Error tracing variables: ", err);
      } else {
        variableValues = result;
      }

    });

  },

  updateChosen() {

    // All lines should be reset to being non-highlighted.
    $('div.line').removeClass('chosen').removeClass('unchosen');

    // XXX: Another HTML hack: find the lines on the page that correspond
    // to the main editor, and highlight those lines.
    examplifyEditorLines = $(
      'atom-pane[data-active-item-name="' + examplifyEditor.getTitle() + '"] ' +
      'div.line');

    examplifyEditorLines.each((i, line) => {
      lineIndex = Number($(line).data('screenRow'));
      if (includedLines.indexOf(lineIndex) !== -1) {
        console.log("Chosen");
        $(line).addClass('chosen');
      } else {
        $(line).addClass('unchosen');
      }
    });

  },

  highlightDefinitions(undefinedMarker, symbol) {

    // Create mark for the nearest definition of the symbol
    symbolAppearance = new SymbolAppearance(
      symbol.symbolName,
      symbol.lineNumber,
      symbol.startPosition,
      symbol.endPosition
    );
    if (dataflowAnalysis !== undefined) {
      definition = dataflowAnalysis.getLatestDefinitionBeforeUseSync(symbolAppearance);
      definitionLineNumber = definition.getLineNumberSync();
      definitionStartPosition = definition.getStartPositionSync();
      definitionEndPosition = definition.getEndPositionSync();
      definitionRange = new Range(
        [definitionLineNumber - 1, definitionStartPosition],
        [definitionLineNumber - 1, definitionEndPosition]
      );
      editor = atom.workspace.getActiveTextEditor();
      definitionMarker = editor.markBufferRange(definitionRange, {
        invalidate: 'never'
      });
      definitionMarkers.push(definitionMarker);
    }

    // This is the container of different options of ways to define code
    definitionOptions = $("<div></div>");

    // This button lets one preview and insert constant value for the variable
    // We need access to the editor so we can show a preview of a new value.
    editor = atom.workspace.getActiveTextEditor();

    if (variableValues !== undefined) {

      value = this.getVariableValue(symbol.symbolName, symbol.lineNumber);

      originalText = editor.getTextInBufferRange(undefinedMarker.getBufferRange());
      insertOption = $("<div class=definition-option>Insert Data</div>");

      // Only give user the option of inserting the value if a value was found
      // at some point in the runtime data.
      if (value !== undefined) {
        insertOption.mouseover((event) => {
            editor.setTextInBufferRange(undefinedMarker.getBufferRange(), String(value));
          }).mouseout((event) => {
            editor.setTextInBufferRange(undefinedMarker.getBufferRange(), originalText);
          }).click((event) => {
            this.clearDefinitionMarkers();
            // It's important to re-run analysis because there are no longer the
            // same dependencies in the same locations when replacements were made.
            // XXX: currently we save the file to make sure analysis is run on
            // updated code.  In the future, it's better to make a temporary one.
            editor.save();
            this.analyze();
          });
      } else {
        insertOption.addClass("disabled");
      }

      definitionOptions.append(insertOption);
    }

    // This button lets one preview what lines of code need to be added
    if (definitionMarker !== undefined) {
      definitionDecoration = undefined;
      defineOption = $("<div class=definition-option>Add Definition</div>")
        .mouseover((event) => {
          definitionDecoration = editor.decorateMarker(definitionMarker, {
            type: 'line',
            class: 'definition'
          });
        }).mouseout((event) => {
          if (definitionDecoration !== undefined) {
            definitionDecoration.destroy();
          }
        }).click((event) => {
          includedLines.push(definitionLineNumber - 1);
          this.updateChosen();
          this.clearDefinitionMarkers();
          this.highlightUndefined();
        });
      definitionOptions.append(defineOption);
    }

    // The first marker is a clickable button for repair
    editor.decorateMarker(undefinedMarker, {
      type: 'overlay',
      item: definitionOptions,
      position: 'tail',
      class: 'pick-overlay'
    });

  },

  highlightUndefined() {

    if (dataflowAnalysis === undefined) return;

    // Convert the list of selected lines to a list that can be
    // passed to our static analysis too.
    lineList = java.newInstanceSync("java.util.ArrayList");
    for (i = 0; i < includedLines.length; i++) {
      // Note: the line indexes from the range are zero-indexed,
      // while the indexes in Soot and in the visible editor are
      // one-indexed.  So we add one to each of the lines before
      // calling on the analysis methods.
      lineList.addSync(includedLines[i] + 1);
    }

    // The rest of the calls to DataflowAnalysis are pretty much
    // just operations on lists and counting.  Can do synchronounsly
    // for now to keep this code looking nice
    result = dataflowAnalysis.getUndefinedUsesInLinesSync(lineList);
    undefinedUses = result.toArraySync();

    // For each of the undefined uses, highlight them in the editor
    undefinedUses.forEach((use) => {

      // See note above about zero-indexing vs one-indexing
      symbol = {
        symbolName: use.getSymbolNameSync(),
        lineNumber: use.getLineNumberSync(),
        startPosition: use.getStartPositionSync(),
        endPosition: use.getEndPositionSync()
      };
      // console.log("Symbol:", symbol);
      range = new Range(
        [symbol.lineNumber - 1, symbol.startPosition],
        [symbol.lineNumber - 1, symbol.endPosition]
      );

      editor = atom.workspace.getActiveTextEditor();
      marker = editor.markBufferRange(range, {
        invalidate: 'never'
      });
      definitionMarkers.push(marker);

      // Save all of the metadata so we can find this use symbol
      // when we query the dataflow analysis again
      definitionButton = $('<div>Click to define.</div>')
        .data('symbol', symbol)
        .click((event) => {
          symbol = $(event.target).data('symbol');
          this.clearDefinitionMarkers([marker]);
          this.highlightDefinitions(marker, symbol);
        });

      // The first marker is a clickable button for repair
      editor.decorateMarker(marker, {
        type: 'overlay',
        item: definitionButton,
        position: 'tail',
        class: 'definition-overlay'
      });

      // The second one just introduces some error colors
      editor.decorateMarker(marker, {
        type: 'highlight',
        class: 'undefined-use'
      });

    });

  },

  analyze() {

    className = this.getActiveFileClassname();

    // This call is more important to do asynchronously:
    // It might take a few seconds to complete.
    dataflowAnalysis = new DataflowAnalysis(SOOT_CLASSPATH);
    dataflowAnalysis.analyze(className, (err, result) => {

      if (err) {
        console.error(err);
        return;
      } else {
        this.highlightUndefined();
      }

    });

    // At the same time as doing dataflow analysis, we also run the program
    // through a debugger to get the values of the variables at each step.
    this.refreshVariableValues();

  },

  activate(state) {

    // Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    this.subscriptions = new CompositeDisposable();

    // Register command for making example code
    this.subscriptions.add(atom.commands.add('atom-workspace', {
      'examplify:make-example-code': () => {

        // Highlight selected lines.  Obscure all others
        editor = atom.workspace.getActiveTextEditor();
        examplifyEditor = editor;
        range = editor.getSelectedBufferRange();
        includedLines = range.getRows();
        this.updateChosen();

        // Run dataflow analysis on the chosen lines
        classname = this.getActiveFileClassname();
        this.analyze(classname);

      }

    }));

    // XXX: Unfold all folds in editors to make sure our highlighting tricks
    // align to the right line indexes in the DOM.
    atom.workspace.observeTextEditors((editor) => {
      editor.unfoldAll();
    });

    // XXX: Whenever the DOM is changed, we need to make sure that lines are
    // highlighted in the same way.  The line `div`s change whenever they
    // scroll on or off-screen, or when their content changes.  This ruins
    // the highlighting effect we're working with.
    scrollObserver = new MutationObserver((mutations, observer) => {
      this.updateChosen();
    });
    scrollObserver.observe(
      document.querySelector('atom-pane-container.panes'),
      { childList: true, subtree: true }
    );

    // XXX: And whenever we switch editors (which apparently we can only)
    // detect by watching the DOM) update the highlighting rules
    editorChangeObserver = new MutationObserver((mutations, observer) => {
      this.updateChosen();
    });
    editorChangeObserver.observe(
      document.querySelector('atom-pane.pane.active'),
      { attributes: true }
    );

  },

  deactivate() {
    this.subscriptions.dispose();
  },

  serialize() {
    return {};
  },

};
