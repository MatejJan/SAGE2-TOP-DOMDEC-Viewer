class TopViewer.ColorControl
  @presets: [
    'black'
    'dimgrey'
    'grey'
    'darkgrey'
    'silver'
    'gainsboro'
    'white'
    'slategrey'
    'steelblue'
    'lightsteelblue'
    'indianred'
    'wheat'
    'cadetblue'
    'darkseagreen'
  ]

  constructor: (@uiArea, @options) ->
    @_components = h: 0, s: 0, l: 0

    # Set the initial value.
    @value = new THREE.Color()

    # Try to set it from options.
    @value = @options.value if @options.value

    # Try to set it from save state.
    if @options.saveState
      @value.setHSL @options.saveState.h / 360, @options.saveState.s / 100, @options.saveState.l / 100

    # Build the UI.
    @$element = $("<div class='color-control #{@options.class}'></div>")
    @options.$parent.append(@$element)

    # Dropdown dialog
    @$dialog = $("<div class='dialog'>")

    @dialogControl = new TopViewer.ToggleContainer @uiArea,
      $parent: @$element
      text: ""
      visible: false
      $contents: @$dialog

    uiControl = new TopViewer.UIControl @uiArea, @$element
    uiControl.globalMouseup (position) =>
      clickedControl = @uiArea.hoveredControl

      # Are we even inside this area?
      return if @$element.has(clickedControl?.$element).length

      @dialogControl.toggleControl.setValue false

    # Presets
    @$presetsArea = $("<div class='presets-area'></div>")
    @$dialog.append(@$presetsArea)

    @$presets = $("<ul class='presets'></ul>")
    @$presetsArea.append(@$presets)

    for preset in @constructor.presets
      do (preset) =>
        $preset = $("<li class='preset' style='background: #{preset};'></li>")
        @$presets.append($preset)

        presetControl = new TopViewer.UIControl @uiArea, $preset
        presetControl.mousedown (position) =>
          @setValue new THREE.Color preset

          @dialogControl.toggleControl.setValue false

    # Color sliders
    @$colorSliders = $("<div class='color-sliders'></div>")
    @$dialog.append(@$colorSliders)

    addSlider = (name, unit, maximumValue, onChange) =>
      $sliderArea = $("<div class='slider-area'><span class='name'>#{name}</span></div>")
      @$colorSliders.append($sliderArea)

      new TopViewer.SliderControl @uiArea,
        $parent: $sliderArea
        minimumValue: 0
        maximumValue: maximumValue
        decimals: 0
        unit: unit
        unitWithoutSpace: true
        onChange: (value) => onChange value

    @sliders =
      h: addSlider "H", "°", 360, (value) => @_updateComponent 'h', value
      s: addSlider "S", "%", 100, (value) => @_updateComponent 's', value
      l: addSlider "L", "%", 100, (value) => @_updateComponent 'l', value

    # Add the color preview inside the dropdown label.
    @$colorPreview = $("<div class='color-preview'></div>")
    @dialogControl.toggleControl.$element.text('').append(@$colorPreview)

    # Reset the value so that sliders get updated.
    @setValue @value

  setValue: (value) ->
    @value = value

    # Update components.
    @_components = @value.getHSL()
    @_components.h *= 360
    @_components.s *= 100
    @_components.l *= 100

    # Update sliders, but don't trigger slider's handlers.
    for component, value of @_components
      @sliders[component].setValue value, true

    @_colorChanged()

  _updateComponent: (component, value) ->
    # This is an internal handler for changing one component at a time on slider change.
    @_components[component] = value

    # Update value.
    @value.setHSL @_components.h / 360, @_components.s / 100, @_components.l / 100

    @_colorChanged()

  _colorChanged: ->
    # Update color preview in the UI.
    @$colorPreview.css
      background: "hsl(#{@_components.h}, #{@_components.s}%, #{@_components.l}%)"

    # Save into state.
    _.extend @options.saveState, @_components if @options.saveState

    # Report the change.
    @options.onChange? @value
