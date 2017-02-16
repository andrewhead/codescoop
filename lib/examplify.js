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

// Load up the Java objects we want to use
SOOT_CLASSPATH = java.classpath.join(':');
SOOT_CLASSPATH = SOOT_CLASSPATH + ':' + THIS_PACKAGE_PATH + '/java/tests/';
DataflowAnalysis = java.import("DataflowAnalysis");
SymbolAppearance = java.import("SymbolAppearance");
dataflowAnalysis = undefined;

// Globals
// List of markers that can be invalidated when a new choice was made
dataflowMarkers = [];
// Working set of lines that are currently being used in the example
includedLines = [];


export default {

  examplifyView: null,
  modalPanel: null,
  subscriptions: null,

  updateChosen() {
      $('div.line').removeClass('unchosen');
      $('div.line').each((i, line) => {
        lineIndex = Number($(line).data('screenRow'));
        if (includedLines.indexOf(lineIndex) === -1) {
          $(line).addClass('unchosen');
        }
      });
  },

  highlightDefinitions(symbol) {
    symbolAppearance = new SymbolAppearance(
      symbol.symbolName,
      symbol.lineNumber,
      symbol.startPosition,
      symbol.endPosition
    )
    if (dataflowAnalysis !== undefined) {

      definition = dataflowAnalysis.getLatestDefinitionBeforeUseSync(symbolAppearance);
      lineNumber = definition.getLineNumberSync();
      startPosition = definition.getStartPositionSync();
      endPosition = definition.getEndPositionSync();

      // Add a mark to the line that defines the symbol
      range = new Range(
        [lineNumber - 1, startPosition],
        [lineNumber - 1, endPosition]
      );
      editor = atom.workspace.getActiveTextEditor();
      marker = editor.markBufferRange(range, {
        invalidate: 'never'
      });
      editor.decorateMarker(marker, {
        type: 'line',
        class: 'definition'
      });
      dataflowMarkers.push(marker);

      pickButton = $('<div>Pick this def?</div>')
        .click((event) => {
          dataflowMarkers.forEach((marker) => {
            marker.destroy();
            includedLines.push(lineNumber - 1);
            this.updateChosen();
            this.highlightUndefined();
          })
        });
      editor.decorateMarker(marker, {
        type: 'overlay',
        item: pickButton,
        position: 'tail',
        class: 'pick-overlay'
      });

    }
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
      range = new Range(
        [symbol.lineNumber - 1, symbol.startPosition],
        [symbol.lineNumber - 1, symbol.endPosition]
      );

      editor = atom.workspace.getActiveTextEditor();
      marker = editor.markBufferRange(range, {
        invalidate: 'inside'
      });
      dataflowMarkers.push(marker);

      // Save all of the metadata so we can find this use symbol
      // when we query the dataflow analysis again
      definitionButton = $('<div>Click to define.</div>')
        .data('symbol', symbol)
        .click((event) => {
          symbol = $(event.target).data('symbol');
          this.highlightDefinitions(symbol);
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

  analyze(className) {

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

  },

  activate(state) {

    // Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    this.subscriptions = new CompositeDisposable();

    // Register command for making example code
    this.subscriptions.add(atom.commands.add('atom-workspace', {
      'examplify:make-example-code': () => {

        // Highlight selected lines.  Obscure all others
        editor = atom.workspace.getActiveTextEditor();
        range = editor.getSelectedBufferRange();
        includedLines = range.getRows();
        this.updateChosen();

        // Run dataflow analysis on the chosen lines
        this.analyze("Example");

      }

    }));

  },

  deactivate() {
    this.subscriptions.dispose();
  },

  serialize() {
    return {};
  },

};
