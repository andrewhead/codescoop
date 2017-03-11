{ ControlLogicSuggestion } = require "./suggestion"

module.exports.AddControlLogicSuggester = class AddControlLogicSuggester

  getSuggestions: (concern, model) ->
    context = concern.getContext()
    suggestions = []
    suggestion = new ControlLogicSuggestion context.getName(), context.getRange()
    suggestions.push suggestion
    suggestions
