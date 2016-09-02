'use strict'

class TopViewer.RenderingControls extends TopViewer.UIArea
  @MeshSurfaceSides:
    SingleFront: 'SingleFront'
    SingleBack: 'SingleBack'
    DoubleFast: 'DoubleFast'
    DoubleQuality: 'DoubleQuality'

  @VertexColorsType:
    Color: 'Color'
    Scalar: 'Scalar'

  constructor: (@options) ->
    super

    saveState = @options.engine.options.app.state.renderingControls
    @$appWindow = @options.engine.$appWindow
    @scene = @options.engine.scene

    # Construct the html of rendering controls.
    @$controls = $("<div class='rendering-controls'>")
    @$appWindow.append @$controls

    # Set the roots.
    @$rootElement = @$controls
    @rootControl = new TopViewer.UIControl @, @$controls

    # Setup scrolling.
    scrollOffset = 0
    @rootControl.scroll (delta) =>
      scrollOffset += delta
      scrollOffset = Math.max scrollOffset, 0
      scrollOffset = Math.min scrollOffset, @$controls.height() - @options.engine.$appWindow.height() * 0.8

      @$controls.css
        top: -scrollOffset

    # Lighting

    $lightingArea = $("<div class='lighting-area'></div>")
    new TopViewer.ToggleContainer @,
      $parent: @$controls
      text: "Lighting"
      class: "panel"
      visible: saveState.lighting.panelEnabled
      $contents: $lightingArea
      onChange: (value) =>
        saveState.lighting.panelEnabled = value

    @lightingSetupControl = new TopViewer.DropdownControl @,
      $parent: $lightingArea
      class: 'lighting-setup-dropdown'
      onChange: (value, control) =>
        saveState.lighting.lightingSetup =
          name: control.dropdownControl.options.text
          value: value.lightDirection

    for lightingPreset in @options.engine.lightingPresets
      @lightingSetupControl.addValue lightingPreset.name, lightingPreset

    if saveState.lighting.lightingSetup.name
      found = @lightingSetupControl.setValue saveState.lighting.lightingSetup.name

      unless found
        customLight = new LightingSetup saveState.lightingSetup.name, saveState.lightingSetup.value
        @lightingSetupControl.setValueDirectly customLight.name, customLight

    else
      @lightingSetupControl.setValue @options.engine.lightingPresets[0]

    @bidirectionalLightControl = new TopViewer.CheckboxControl @,
      $parent: $lightingArea
      name: 'Bidirectional'
      value: saveState.lighting.bidirectional
      onChange: (value) =>
        saveState.lighting.bidirectional = value

    @shadowsControl = new TopViewer.CheckboxControl @,
      $parent: $lightingArea
      name: 'Cast shadows'
      value: saveState.lighting.shadows
      onChange: (value) =>
        saveState.lighting.shadows = value
        @options.engine.scene.update()

    $lightingArea.append("<p class='label'>Ambient light</p>")

    @ambientLevelControl = new TopViewer.SliderControl @,
      $parent: $lightingArea
      minimumValue: 0
      maximumValue: 1
      value: saveState.lighting.ambient
      decimals: -2
      onChange: (value) =>
        saveState.lighting.ambient = value

    # Colors

    $gradientArea = $("<div class='gradient-area'></div>")
    new TopViewer.ToggleContainer @,
      $parent: @$controls
      text: "Colors"
      class: "panel"
      visible: saveState.gradient.panelEnabled
      $contents: $gradientArea
      onChange: (value) =>
        saveState.gradient.panelEnabled = value

    $gradientPreview = $("<div class='gradient-preview-area'><img class='gradient-preview-image'/></div>")
    gradientPreviewImage = $gradientPreview.find('img')[0]

    @gradientControl = new TopViewer.DropdownControl @,
      $parent: $gradientArea
      class: 'gradient-dropdown'
      onChange: (value) =>
        gradientPreviewImage.src = value.url
        saveState.gradient.name = value.name

    for gradient in @options.engine.gradients
      @gradientControl.addValue gradient.name, gradient

    found = false
    found = @gradientControl.setValue saveState.gradient.name if saveState.gradient.name
    console.log "got name", saveState.gradient.name, found
    @gradientControl.setValue @options.engine.gradients[0] unless found

    $gradientArea.append $gradientPreview

    # Meshes

    $meshesArea = $("<div class='meshes-area'></div>")
    new TopViewer.ToggleContainer @,
      $parent: @$controls
      text: "Meshes"
      class: "panel"
      visible: saveState.meshes.panelEnabled
      $contents: $meshesArea
      onChange: (value) =>
        saveState.meshes.panelEnabled = value

    # Surface

    $meshesSurfaceArea = $("<div class='surface-area sub-panel first'><div class='title'>Surface</div></div>")
    $meshesArea.append $meshesSurfaceArea

    @meshesShowSurfaceControl = new TopViewer.CheckboxControl @,
      $parent: $meshesSurfaceArea
      name: 'Enable'
      value: saveState.meshes.surfaceEnabled
      onChange: (value) =>
        saveState.meshes.surfaceEnabled = value

    @meshesSurfaceSidesControl = new TopViewer.DropdownControl @,
      $parent: $meshesSurfaceArea
      class: 'meshes-surface-sides-selector'
      onChange: (value) =>
        saveState.meshes.surfaceSides = value

    @meshesSurfaceSidesControl.addValue 'Single Sided (front)', @constructor.MeshSurfaceSides.SingleFront
    @meshesSurfaceSidesControl.addValue 'Single Sided (back)', @constructor.MeshSurfaceSides.SingleBack
    @meshesSurfaceSidesControl.addValue 'Double Sided (fast)', @constructor.MeshSurfaceSides.DoubleFast
    @meshesSurfaceSidesControl.addValue 'Double Sided (quality)', @constructor.MeshSurfaceSides.DoubleQuality

    @meshesSurfaceSidesControl.setValue saveState.meshes.surfaceSides

    @meshesSurfaceColorsControl = new TopViewer.VertexColorsControl @,
      $parent: $meshesSurfaceArea
      class: 'meshes-surface-colors-selector'
      saveState: saveState.meshes.surfaceColors

    $meshesSurfaceArea.append("<p class='label'>Opacity</p>")
    @meshesSurfaceOpacityControl = new TopViewer.SliderControl @,
      $parent: $meshesSurfaceArea
      minimumValue: 0
      maximumValue: 1
      value: saveState.meshes.surfaceOpacity
      decimals: -2
      onChange: (value) =>
        saveState.meshes.surfaceOpacity = value

    # Wireframe

    $meshesWireframeArea = $("<div class='wireframe-area sub-panel'><div class='title'>Wireframe</div></div>")
    $meshesArea.append $meshesWireframeArea

    @meshesShowWireframeControl = new TopViewer.CheckboxControl @,
      $parent: $meshesWireframeArea
      name: 'Enable'
      value: saveState.meshes.wireframeEnabled
      onChange: (value) =>
        saveState.meshes.wireframeEnabled = value

    @meshesWireframeColorsControl = new TopViewer.VertexColorsControl @,
      $parent: $meshesWireframeArea
      class: 'meshes-wireframe-colors-selector'
      saveState: saveState.meshes.wireframeColors

    $meshesWireframeArea.append("<p class='label'>Opacity</p>")
    @meshesWireframeOpacityControl = new TopViewer.SliderControl @,
      $parent: $meshesWireframeArea
      minimumValue: 0
      maximumValue: 1
      value: saveState.meshes.wireframeOpacity
      decimals: -2
      onChange: (value) =>
        saveState.meshes.wireframeOpacity = value

    # Isolines

    $meshesIsolinesArea = $("<div class='isolines-area sub-panel'><div class='title'>Isolines</div></div>")
    $meshesArea.append $meshesIsolinesArea

    @meshesShowIsolinesControl = new TopViewer.CheckboxControl @,
      $parent: $meshesIsolinesArea
      name: 'Enable'
      value: saveState.meshes.isolinesEnabled
      onChange: (value) =>
        saveState.meshes.isolinesEnabled = value

    @meshesIsolinesScalarControl = new TopViewer.ScalarControl @,
      $parent: $meshesIsolinesArea
      saveState: saveState.meshes.isolinesScalar

    @meshesIsolinesColorsControl = new TopViewer.VertexColorsControl @,
      $parent: $meshesIsolinesArea
      class: 'meshes-isolines-colors-selector'
      saveState: saveState.meshes.isolinesColors

    $meshesIsolinesArea.append("<p class='label'>Opacity</p>")
    @meshesIsolinesOpacityControl = new TopViewer.SliderControl @,
      $parent: $meshesIsolinesArea
      minimumValue: 0
      maximumValue: 1
      value: saveState.meshes.isolinesOpacity
      decimals: -2
      onChange: (value) =>
        saveState.meshes.isolinesOpacity = value

    # Volumes

    $volumesArea = $("<div class='volumes-area'></div>")
    new TopViewer.ToggleContainer @,
      $parent: @$controls
      text: "Volumes"
      class: "panel"
      visible: saveState.volumes.panelEnabled
      $contents: $volumesArea
      onChange: (value) =>
        saveState.volumes.panelEnabled = value

    # Wireframe

    $volumesWireframeArea = $("<div class='wireframe-area sub-panel'><div class='title'>Wireframe</div></div>")
    $volumesArea.append $volumesWireframeArea

    @volumesShowWireframeControl = new TopViewer.CheckboxControl @,
      $parent: $volumesWireframeArea
      name: 'Enable'
      value: saveState.volumes.wireframeEnabled
      onChange: (value) =>
        saveState.volumes.wireframeEnabled = value

    @volumesWireframeColorsControl = new TopViewer.VertexColorsControl @,
      $parent: $volumesWireframeArea
      class: 'volumes-wireframe-colors-selector'
      saveState: saveState.volumes.wireframeColors

    $volumesWireframeArea.append("<p class='label'>Opacity</p>")
    @volumesWireframeOpacityControl = new TopViewer.SliderControl @,
      $parent: $volumesWireframeArea
      minimumValue: 0
      maximumValue: 1
      value: saveState.volumes.wireframeOpacity
      decimals: -2
      onChange: (value) =>
        saveState.volumes.wireframeOpacity = value

    # Isosurfaces

    $volumesIsosurfacesArea = $("<div class='isosrufaces-area sub-panel'><div class='title'>Isosurfaces</div></div>")
    $volumesArea.append $volumesIsosurfacesArea

    @volumesShowIsosurfacesControl = new TopViewer.CheckboxControl @,
      $parent: $volumesIsosurfacesArea
      name: 'Enable'
      value: saveState.volumes.isosurfacesEnabled
      onChange: (value) =>
        saveState.volumes.isosurfacesEnabled = value

    @volumesIsosurfacesScalarControl = new TopViewer.ScalarControl @,
      $parent: $volumesIsosurfacesArea
      saveState: saveState.volumes.isosurfacesScalar

    @volumesIsosurfacesColorsControl = new TopViewer.VertexColorsControl @,
      $parent: $volumesIsosurfacesArea
      class: 'volumes-isosurfaces-colors-selector'
      saveState: saveState.volumes.isosurfacesColors

    $volumesIsosurfacesArea.append("<p class='label'>Opacity</p>")
    @volumesIsosurfacesOpacityControl = new TopViewer.SliderControl @,
      $parent: $volumesIsosurfacesArea
      minimumValue: 0
      maximumValue: 1
      value: saveState.volumes.isosurfacesOpacity
      decimals: -2
      onChange: (value) =>
        saveState.volumes.isosurfacesOpacity = value


    # TODO: OLD CONTROLS

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
        value: true

      wireframe: new TopViewer.CheckboxControl @,
        $parent: $contents
        name: 'wireframe'
        value: false

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
    TopViewer.ScalarControl.addScalar name, scalar

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
