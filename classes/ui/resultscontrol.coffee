class TopViewer.ResultsControl
  constructor: (@uiArea, @options) ->
    @constructor._resultsControls.push @

    # Build the UI.
    @$element = $("<div class='results-control #{@options.class}'></div>")
    @options.$parent.append(@$element)

    @resultsSelectionControl = new TopViewer.DropdownControl @uiArea,
      $parent: @$element
      class: 'results-selector'
      value: null
      text: @options.saveState.name or 'None'
      onChange: (value) =>
        @options.saveState.name = @resultsSelectionControl.dropdownControl.options.text
        @value = value

    # Right now we only add the None value, but we've set the active text on the dropdown to the save state. Until
    # the results gets loaded, the value will remain null, but once the results with the given name is loaded, its value
    # will be set behind the scenes.
    @resultsSelectionControl.addValue 'None', null

    # If some results have already been added, add those as well.
    @resultsSelectionControl.addValue results.name, results.results for results in @constructor._addedResults

    # Otherwise select it if none other is set.
    if @constructor.autoloadFirst and @constructor._addedResults.length  and not @resultsSelectionControl.dropdownControl.value
      @resultsSelectionControl.setValue @constructor._addedResults[0]

  @addResults: (name, results) ->
    control.addResults name, results for control in @_resultsControls

    @_addedResults.push
      name: name
      results: results

  addResults: (name, results) ->
    @resultsSelectionControl.addValue name, results

    # See if this results is the one set on the dropdown from save state.
    if name is @resultsSelectionControl.dropdownControl.options.text
      # We loaded the results we've been waiting for so set it.
      @resultsSelectionControl.setValue results

    # Otherwise select it if none other is set.
    if @constructor.autoloadFirst and not @resultsSelectionControl.dropdownControl.value
      @resultsSelectionControl.setValue results

class TopViewer.ScalarControl extends TopViewer.ResultsControl
  @_resultsControls = []
  @_addedResults = []
  @autoloadFirst = true

class TopViewer.VectorControl extends TopViewer.ResultsControl
  @_resultsControls = []
  @_addedResults = []
