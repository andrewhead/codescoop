# This command stack expects each element to be a group of commands
# that was executed together.  It "pops" this group of commands together,
# so that they can be executed all as one undo action.
module.exports.CommandStack = class CommandStack

  constructor: ->
    @stack = []

  push: (commandGroup) ->
    @stack.push commandGroup

  pop: ->
    @stack.pop()

  peek: ->
    @stack[@stack.length - 1]

  getHeight: ->
    @stack.length
