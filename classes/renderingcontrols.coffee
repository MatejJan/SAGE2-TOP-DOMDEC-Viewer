'use strict'

class TopViewer.RenderingControls extends TopViewer.UIArea
  constructor: (@options) ->
    super

    @$appWindow = @options.engine.$appWindow
    @scene = @options.engine.scene

    @$controls = $("<div class='rendering-controls'>")

    @$appWindow.append @$controls

    @rootControl = new TopViewer.UIControl @, @$controls

    $displacementArea = $("<div class='displacement-area panel'><div class='title'>Displacement</div></div>")
    @$controls.append $displacementArea

    @displacementDropdown = new TopViewer.DropdownControl @,
      $parent: $displacementArea
      class: 'displacement-selector'
      value: null
      text: 'None'

    @displacementDropdown.addValue 'None', null

    @displacementFactor = new TopViewer.SliderControl @,
      $parent: $displacementArea
      class: 'displacement-factor'
      minimumValue: 0
      maximumValue: 100
      power: 4
      value: 1
      decimals: -2

    $mainGeometryArea = $("<div class='main-geometry-area panel'><div class='title'>Main Geometry</div></div>")
    @$controls.append $mainGeometryArea

    @mainGeometrySurfaceControl = new TopViewer.CheckboxControl @,
      $parent: $mainGeometryArea
      name: 'surface'
      value: true

    @mainGeometrySurfaceDropdown = new TopViewer.DropdownControl @,
      $parent: $mainGeometryArea
      class: 'main-geometry-result-selector'
      value: null
      text: 'None'

    @mainGeometrySurfaceDropdown.addValue 'None', null

    $mainGeometryArea.append("""
      <div class='gradient-curve'>
        <canvas height='256' width='256'></canvas>
      </div>
    """)

    @gradientCurve = new ColorCurve $mainGeometryArea.find('.gradient-curve canvas')[0]

    @mainGeometrySurfaceWireframeControl = new TopViewer.CheckboxControl @,
      $parent: $mainGeometryArea
      name: 'wireframe'
      value: false

    @$controls.append("<hr/>")

    @$meshes = $("<ul class='meshes'></ul>")
    @$controls.append(@$meshes)

    @$controls.append("<hr/>")

    @$vectors = $("<ul class='vectors'></ul>")
    @$controls.append(@$vectors)

  addMesh: (name, mesh) ->
    $mesh = $("<li class='mesh'></li>")
    @$meshes.append($mesh)

    $contents = $("<div>")

    mesh.renderingControls =
      surface: new TopViewer.CheckboxControl @,
        $parent: $contents
        name: 'surface'
        value: false

      wireframe: new TopViewer.CheckboxControl @,
        $parent: $contents
        name: 'wireframe'
        value: true

      isolines: new TopViewer.CheckboxControl @,
        $parent: $contents
        name: 'isolines'
        value: false

    new TopViewer.ToggleContainer @,
      $parent: $mesh
      text: name
      visible: false
      $contents: $contents

  addVolume: (name, mesh) ->
    $mesh = $("<li class='mesh'></li>")
    @$meshes.append($mesh)

    $contents = $("<div>")

    mesh.renderingControls =
      wireframe: new TopViewer.CheckboxControl @,
        $parent: $contents
        name: 'wireframe'
        value: false

      isosurfaces: new TopViewer.CheckboxControl @,
        $parent: $contents
        name: 'isosurfaces'
        value: true

    new TopViewer.ToggleContainer @,
      $parent: $mesh
      text: name
      visible: false
      $contents: $contents

  addScalar: (name, scalar) ->
    @mainGeometrySurfaceDropdown.addValue name, scalar
    @mainGeometrySurfaceDropdown.setValue scalar unless @mainGeometrySurfaceDropdown.value

  addVector: (name, vector) ->
    $vector = $("<li class='vector'></li>")
    @$vectors.append($vector)

    $contents = $("<div>")

    new TopViewer.ToggleContainer @,
      $parent: $vector
      text: name
      visible: false
      $contents: $contents

    @displacementDropdown.addValue name, vector
    @displacementDropdown.setValue vector if name.toLowerCase().indexOf('disp') > -1

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
