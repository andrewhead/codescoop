{ ControlLogicSuggestion } = require "./suggestion"

module.exports.ControlLogicSuggester = class ControlLogicSuggester

  getSuggestions: (concern) ->
    console.log 'concern', concern

    controlLogicType = concern.controlCtx.children[0].symbol.text #keyword if or for or something

    innerStatement = concern.controlCtx.children[2]
    startControl = concern.controlCtx.start

    startFirstRange= [startControl.line, startControl.column]
    endFirstRange = [innerStatement.start.line, innerStatement.start.column]
    start2ndRange = [innerStatement.stop.line, innerStatement.stop.column-1]
    end2ndRange = [innerStatement.stop.line, innerStatement.stop.column]

    controlRanges = []
    controlRanges.push new Range startFirstRange, endFirstRange
    controlRanges.push new Range start2ndRange, end2ndRange

    suggestion = new ControlLogicSuggestion controlLogicType, controlRanges

    suggestions = []
    suggestions.push suggestion
    suggestions
