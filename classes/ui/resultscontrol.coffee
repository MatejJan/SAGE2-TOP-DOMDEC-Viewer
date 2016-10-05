class TopViewer.ResultsControl
  constructor: (@uiArea, @options) ->
    @uiArea[@constructor.controlsCollectionName].push @

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

    # We've set the active text on the dropdown to the save state, but until the results gets loaded, the value will
    # remain null. Once the results with the given name is loaded, its value will be set behind the scenes.
    @updateResults()

  updateResults: ->
    @resultsSelectionControl.reset()

    @resultsSelectionControl.addValue 'None', null

    for name, result of @loadedResults()
      # Add the value to the dropdowns and hide it by default.
      @resultsSelectionControl.addValue name, result.result
      @resultsSelectionControl.getValueItem(name).hide()

      # See if this results is the one set on the dropdown from save state.
      if name is @resultsSelectionControl.dropdownControl.options.text
        # We loaded the results we've been waiting for so set it.
        @resultsSelectionControl.setValue result.result

  displayResult: (name, visible) ->
    # Show or hide the dropdown item.
    @resultsSelectionControl.getValueItem(name).toggle(visible)

    # If we currently don't have anything selected, handle autoloading.
    if visible and @resultsSelectionControl.options.text is 'None'
      # The autoloadFirst always loads the first item to be displayed.
      autoload = @constructor.autoloadFirst

      # We can also try and automatically load if the name matches a supplied regex.
      autoload = true if @options.autoloadNameRegex? and name.match @options.autoloadNameRegex

      # Autoload the result with given name if autoload condition passed.
      @resultsSelectionControl.setValue name if autoload

class TopViewer.ScalarControl extends TopViewer.ResultsControl
  @controlsCollectionName = 'scalarControls'
  @autoloadFirst = true
  loadedResults: -> @uiArea.loadedObjects.scalars

class TopViewer.VectorControl extends TopViewer.ResultsControl
  @controlsCollectionName = 'vectorControls'
  loadedResults: -> @uiArea.loadedObjects.vectors
