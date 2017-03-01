$ = require('jquery');

module.exports.ExampleViewer = class ExampleViewer

  constructor: (textEditor) ->
    @textEditor = textEditor

  setChosenLines: (lines) ->
    @chosenLines = lines
    @repaint()

  getTextEditor: () ->
    @textEditor

  repaint: ->

    exampleCode = [
      "public class SmallScoop {",
      "",
      "    public static void main(String[] args) {",
      "",
    ]

    for line in @chosenLines
      lineTextStripped = line.replace /^\s+/, ''
      exampleCode.push ("        " + lineTextStripped)

    # TODO: Replace this with a prettier pretty-printer
    exampleCode.push ""
    exampleCode.push "    }"
    exampleCode.push ""
    exampleCode.push "}"

    exampleCodeText = exampleCode.join "\n"
    @textEditor.setText exampleCodeText
