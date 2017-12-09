# This command stack expects each element to be a group of commands
# that was executed together.  It "pops" this group of commands together,
# so that they can be executed all as one undo action.
module.exports.CommandStack = class CommandStack

  constructor: ->
    @stack = []
    @listeners = []

  push: (commandGroup) ->
    @stack.push commandGroup
    @notifyListeners()

  pop: ->
    topCommand = @stack.pop()
    @notifyListeners()
    topCommand

  peek: ->
    @stack[@stack.length - 1]

  getHeight: ->
    @stack.length

  addListener: (listener) ->
    @listeners.push listener

  notifyListeners: ->
    for listener in @listeners
      listener.onStackChanged @
