'use babel';

import ExamplifyView from './examplify-view';
import { CompositeDisposable } from 'atom';

THIS_PACKAGE_PATH = atom.packages.resolvePackagePath('examplify');
SCRIPT_PACKAGE_PATH = atom.packages.resolvePackagePath('script');
JAVA_LIBS_DIR = THIS_PACKAGE_PATH + '/java/libs';

// Prepare the gateway to Java code for running static analysis
java = require('java');
fs = require('fs');
libs = fs.readdirSync(JAVA_LIBS_DIR);
java.classpath.push(THIS_PACKAGE_PATH + '/java');
java.classpath.push()
libs.forEach((libName) => {
  java.classpath.push(JAVA_LIBS_DIR + '/' + libName);
});

// Sorry, you'll need to modify this for the Java home on your computer.
// I'm hard-coding it so I can do this fast locally
JAVA_HOME = "/Library/Java/JavaVirtualMachines/jdk1.7.0_67.jdk/Contents/Home";
jre_libs = fs.readdirSync(JAVA_HOME + '/jre/lib');
jre_libs.forEach((libName) => {
  java.classpath.push(JAVA_HOME + '/jre/lib/' + libName);
});

// Load up the Java objects we want to use
DataflowAnalysis = java.import("DataflowAnalysis");

// Make a 'runner' for executing command line stuff (like javac and java)
// I don't think we need this right now, but we might later.
SHELL_CLASSPATH = java.classpath.join(':');
Runner = require(SCRIPT_PACKAGE_PATH + '/lib/runner');
CodeContext = require(SCRIPT_PACKAGE_PATH + '/lib/code-context');
ScriptOptions = require(SCRIPT_PACKAGE_PATH + '/lib/script-options');
scriptOptions = ScriptOptions.createFromOptions('soot-runner', {});
runner = new Runner(scriptOptions);
runner.onDidWriteToStdout((event) => console.log(event.message))
// codeContext = new CodeContext('Example.java', '.');

export default {

  examplifyView: null,
  modalPanel: null,
  subscriptions: null,

  analyze(filePath) {

      sootClasspath = java.classpath.join(':');
      sootClasspath = sootClasspath + ':' + THIS_PACKAGE_PATH + '/tests/';
      console.log(sootClasspath);

      java.newInstance('DataflowAnalysis', (err, dataflowAnalysis) => {
          dataflowAnalysis.analyze(sootClasspath, "Example", (err, result) => {
              console.log("Err:", err);
              console.log("Result:", result);
          });
      });

  },

  activate(state) {

    this.analyze("whatever");

    this.examplifyView = new ExamplifyView(state.examplifyViewState);
    this.modalPanel = atom.workspace.addModalPanel({
      item: this.examplifyView.getElement(),
      visible: false
    });

    // Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    this.subscriptions = new CompositeDisposable();

    // Register command for making example code
    this.subscriptions.add(atom.commands.add('atom-workspace', {
      'examplify:make-example-code': () => {

        editor = atom.workspace.getActiveTextEditor();
        range = editor.getSelectedBufferRange();
        chosenRows = range.getRows();

        lines = document.querySelectorAll('div.line');
        lines.forEach((line) => {
          lineIndex = Number(line.dataset['screenRow']);
          if (chosenRows.indexOf(lineIndex) !== -1) {
            line.className += ' chosen';
            console.log("Chosen");
          } else {
            line.className += ' unchosen';
            console.log("Unchosen");
          }
        })
      }
    }));

  },

  deactivate() {
    this.modalPanel.destroy();
    this.subscriptions.dispose();
    this.examplifyView.destroy();
  },

  serialize() {
    return {
      examplifyViewState: this.examplifyView.serialize()
    };
  },

};
