module.exports.AddStubSpec = class AddStubSpec

  constructor: (stubSpec) ->
    @stubSpec = stubSpec

  apply: (model) ->
    model.getStubSpecs().push @stubSpec

  getStubSpec: ->
    @stubSpec
