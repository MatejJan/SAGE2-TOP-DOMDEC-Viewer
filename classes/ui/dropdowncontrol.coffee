class TopViewer.DropdownControl
  constructor: (@uiArea, @options) ->
    @$element = $("""
      <div class="dropdown-control #{@options.class}">
      </div>
    """)

    @$values = $("<ul class='values'>")

    @dropdownControl = new TopViewer.ToggleContainer @uiArea,
      $parent: @$element
      text: @options.text
      visible: false
      $contents: @$values

    @options.$parent.append(@$element)

    @value = @options.value
    @values = []

    # Create the top UI control for hovering purposes.
    new TopViewer.UIControl @uiArea, @$element

  addValue: (text, value) ->
    $item = $("<li class='value'>#{text}</li>")
    @$values.append($item)

    # Create a UI control for hovering purposes.
    control = new TopViewer.UIControl @uiArea, $item
    control.click =>
      # Change the value.
      @setValue value

      # Close the dropdown.
      @dropdownControl.toggleControl.setValue false

    @values.push
      value: value
      text: text
      $item: $item
      control: control

  setValue: (newValue) ->
    @value = newValue

    value = _.find @values, (value) ->
      value.value is newValue

    @dropdownControl.setText value.text
