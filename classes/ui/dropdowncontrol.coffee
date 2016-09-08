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

    uiControl = new TopViewer.UIControl @uiArea, @$element
    uiControl.globalMouseup (position) =>
      # Close the dropdown, but only if we're not clicking inside the dropdown.
      clickedControl = @uiArea.hoveredControl

      # Are we even inside this area?
      return if @$element.has(clickedControl?.$element).length

      @dropdownControl.toggleControl.setValue false

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

  setValue: (valueOrText) ->
    value = _.find @values, (value) ->
      value.value is valueOrText or value.text is valueOrText

    return false unless value

    @value = value.value
    @dropdownControl.setText value.text

    @options.onChange? @value, @

    true

  setValueDirectly: (value, text) ->
    @value = value
    @dropdownControl.setText text

    @options.onChange? @value, @
