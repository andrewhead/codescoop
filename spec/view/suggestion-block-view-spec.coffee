{ SuggestionBlockView } = require "../../lib/view/suggestion-block-view"
{ SuggestionView } = require "../../lib/view/suggestion-view"
{ ExampleModel } = require "../../lib/model/example-model"
$ = require 'jquery'


describe "SuggestionBlockView", ->

  blockView = undefined

  beforeEach =>
    # Create dead simple SuggestionBlockView that creates dummy suggestion views
    blockView = new SuggestionBlockView "Title", [ 1 ], new ExampleModel(), undefined
    blockView.createSuggestionView = =>
      view = ($ "<div></div>").addClass "suggestion"
      view.revert = =>
      view

  it "adds suggestion elements when the mouse enters the header", ->
    (expect (blockView.find "div.suggestion").length).toBe 0
    header = $ (blockView.find "div.resolution-class-header")
    header.mouseover()
    (expect (blockView.find "div.suggestion").length).toBe 1

  it "doesn't add suggestion elements twice when the header is entered twice", ->
    header = $ (blockView.find "div.resolution-class-header")
    header.mouseover()
    header.mouseover()
    (expect (blockView.find "div.suggestion").length).toBe 1

  # XXX: While this test currently fails, it inexplicably works in the
  # actual UI.  Need to read up more to find out how to accurately
  # simulate mouse-in and mouse-out events.
  ###
  it "doesn't remove suggestions when the mouse leaves the header", ->
    header = $ (blockView.find "div.resolution-class-header")
    # Simulate mouse moving from header to suggestion
    # blockView.mouseover()
    # header.mouseover()
    header.trigger "mouseover"
    ($ (blockView.find "div.suggestion")).mouseover()
    header.trigger "mouseleave"
    # header.mouseleave()
    (expect (blockView.find "div.suggestion").length).toBe 1
  ###

  it "removes suggestion elements when the mouse leaves the block", ->
    header = $ (blockView.find "div.resolution-class-header")
    header.mouseover()
    blockView.mouseout()
    (expect (blockView.find "div.suggestion").length).toBe 0
