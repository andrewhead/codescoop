$ = require('jquery');

module.exports.ExampleViewer = class ExampleViewer

  constructor: (textEditor, codeBuffer, chosenLines) ->
    @textEditor = textEditor
    @codeBuffer = codeBuffer
    @setChosenLines chosenLines

  setChosenLines: (lineNumbers) ->
    @chosenLines = lineNumbers
    sortedLines = @chosenLines.sort()
    @lineTexts = ((@codeBuffer.lineForRow i) for i in sortedLines)
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

    for line in @lineTexts
      lineTextStripped = line.replace /^\s+/, ''
      exampleCode.push ("        " + lineTextStripped)

    # TODO: Replace this with a prettier pretty-printer
    exampleCode.push ""
    exampleCode.push "    }"
    exampleCode.push ""
    exampleCode.push "}"

    exampleCodeText = exampleCode.join "\n"
    @textEditor.setText exampleCodeText
