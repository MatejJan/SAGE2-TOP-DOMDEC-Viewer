'use strict'

class TopViewer.RenderingControls extends TopViewer.UIArea
  constructor: (@options) ->
    super

    @$appWindow = @options.engine.$appWindow
    @scene = @options.engine.scene

    @$controls = $("<div class='rendering-controls'>")

    @$appWindow.append @$controls

    @rootControl = new TopViewer.UIControl @, @$controls

    new TopViewer.SliderControl @,
      $parent: @$controls
      class: 'displacement-factor'
      minimumValue: 1
      maximumValue: 100
      value: 1
      onChange: (value) =>
        @displacementFactor = value

    @$controls.append("""
      <div class='gradient-curve'>
        <canvas height='256' width='256'></canvas>
      </div>
    """)

    @gradientCurve = new ColorCurve @$controls.find('.gradient-curve canvas')[0]

    @wireframeControl = new TopViewer.CheckboxControl @,
      $parent: @$controls
      name: 'wireframe'
      value: false
      onChange: (value) =>
        @scene.update()

  onMouseDown: (position, button) ->
    super

    @gradientCurve.mouseDown @transformPositionToPage position

  onMouseMove: (position) ->
    super

    @gradientCurve.mouseMove @transformPositionToPage position

  onMouseUp: (position, button) ->
    super

    @gradientCurve.mouseUp @transformPositionToPage position

  transformPositionToPage: (position) ->
    offset = @$appWindow.offset()

    x: position.x + offset.left
    y: position.y + offset.top
