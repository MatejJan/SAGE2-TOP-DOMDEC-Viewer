class TopViewer.ScalarControl
  @_scalarControls = []

  constructor: (@uiArea, @options) ->
    @constructor._scalarControls.push @

    # Build the UI.
    @$element = $("<div class='scalar-control #{@options.class}'></div>")
    @options.$parent.append(@$element)

    @scalarSelectionControl = new TopViewer.DropdownControl @uiArea,
      $parent: @$element
      class: 'scalar-selector'
      value: null
      text: @options.saveState.name or 'None'
      onChange: (value) =>
        @options.saveState.name = @scalarSelectionControl.dropdownControl.options.text
        @value = value

    # Right now we only add the None value, but we've set the active text on the dropdown to the save state. Until
    # the scalar gets loaded, the value will remain null, but once the scalar with the given name is loaded, its value
    # will be set behind the scenes.
    @scalarSelectionControl.addValue 'None', null

  @addScalar: (name, scalar) ->
    control.addScalar name, scalar for control in @_scalarControls

  addScalar: (name, scalar) ->
    @scalarSelectionControl.addValue name, scalar

    # See if this scalar is the one set on the dropdown from save state.
    if name is @scalarSelectionControl.dropdownControl.options.text
      # We loaded the scalar we've been waiting for so set it.
      @scalarSelectionControl.setValue scalar
