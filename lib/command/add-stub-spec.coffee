module.exports.AddStubSpec = class AddStubSpec

  constructor: (stubSpec) ->
    @stubSpec = stubSpec

  apply: (model) ->
    model.getStubSpecs().push @stubSpec

  revert: (model) ->
    model.getStubSpecs().remove @stubSpec

  getStubSpec: ->
    @stubSpec
