'use babel';

import { CompositeDisposable, Range } from 'atom';

THIS_PACKAGE_PATH = atom.packages.resolvePackagePath('examplify');
JAVA_LIBS_DIR = THIS_PACKAGE_PATH + '/java/libs';

// Prepare the gateway to Java code for running static analysis
java = require('java');
fs = require('fs');
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
DataflowAnalysis = java.import("DataflowAnalysis");

export default {

  examplifyView: null,
  modalPanel: null,
  subscriptions: null,

  highlightUndefinedUses(lines) {

  },

  analyze(className, lines) {

      sootClasspath = java.classpath.join(':');
      sootClasspath = sootClasspath + ':' + THIS_PACKAGE_PATH + '/java/tests/';

      dataflowAnalysis = new DataflowAnalysis(sootClasspath);

      // This call is more important to do asynchronously:
      // It might take a few seconds to complete.
      dataflowAnalysis.analyze(className, (err, result) => {

          if (err) {
              console.error(err);
              return;
          }

          // Convert the list of selected lines to a list that can be
          // passed to our static analysis too.
          lineList = java.newInstanceSync("java.util.ArrayList");
          for (i = 0; i < lines.length; i++) {
              // Note: the line indexes from the range are zero-indexed,
              // while the indexes in Soot and in the visible editor are
              // one-indexed.  So we add one to each of the lines before
              // calling on the analysis methods.
              lineList.addSync(lines[i] + 1);
          }

          // The rest of the calls to DataflowAnalysis are pretty much
          // just operations on lists and counting.  Can do synchronounsly
          // for now to keep this code looking nice
          result = dataflowAnalysis.getUndefinedUsesInLinesSync(lineList);
          undefinedUses = result.toArraySync();

          // For each of the undefined uses, highlight them in the editor
          undefinedUses.forEach((use) => {

              // See note above about zero-indexing vs one-indexing
              lineNumber = use.getLineNumberSync();
              startPosition = use.getStartPositionSync();
              endPosition = use.getEndPositionSync();
              range = new Range(
                  [lineNumber - 1, startPosition],
                  [lineNumber - 1, endPosition]
              );

              editor = atom.workspace.getActiveTextEditor();
              marker = editor.markBufferRange(range, {
                invalidate: 'inside'
              });
              editor.decorateMarker(marker, {
                type: 'highlight',
                class: 'undefined-use'
              });

          });

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
        chosenRows = range.getRows();

        lines = document.querySelectorAll('div.line');
        lines.forEach((line) => {
          lineIndex = Number(line.dataset['screenRow']);
          if (chosenRows.indexOf(lineIndex) !== -1) {
            line.className += ' chosen';
          } else {
            line.className += ' unchosen';
          }
        });

        // Run dataflow analysis on the chosen lines
        this.analyze("Example", chosenRows);

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
