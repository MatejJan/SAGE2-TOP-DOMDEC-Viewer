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

    # Preapre for sync handlers.
    @_syncHandlers = []

    # Setup scrolling.
    console.log "got soff", saveState.scrollOffset
    scrollOffset = saveState.scrollOffset or 0
    applyScrollOffset = => @$controls.css top: -scrollOffset

    setTimeout =>
      applyScrollOffset()
    , 1

    @rootControl.scroll (delta) =>
      scrollOffset += delta
      scrollOffset = Math.max scrollOffset, 0
      scrollOffset = Math.min scrollOffset, @$controls.height() - @options.engine.$appWindow.height() * 0.8
      saveState.scrollOffset = scrollOffset
      applyScrollOffset()

    @_onSync (data) =>
      scrollOffset = data.scrollOffset
      applyScrollOffset()

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
        TopViewer.CurveTransformControl.drawSpectrogram()

    for gradient in @options.engine.gradients
      @gradientControl.addValue gradient.name, gradient

    found = false
    found = @gradientControl.setValue saveState.gradient.name if saveState.gradient.name
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

    # Individual meshes

    @$meshes = $("<ul class='meshes sub-panel'></ul>")
    $meshesArea.append(@$meshes)

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

    # Scalars
    
    @$scalarsArea = $("<ul class='scalars-area'></ul>")
    new TopViewer.ToggleContainer @,
      $parent: @$controls
      text: "Scalars"
      class: "panel"
      visible: saveState.scalars.panelEnabled
      $contents: @$scalarsArea
      onChange: (value) =>
        saveState.scalars.panelEnabled = value

    # Vectors

    @$vectorsArea = $("<div class='vectors-area'></div>")
    new TopViewer.ToggleContainer @,
      $parent: @$controls
      text: "Vectors"
      class: "panel"
      visible: saveState.vectors.panelEnabled
      $contents: @$vectorsArea
      onChange: (value) =>
        saveState.vectors.panelEnabled = value

    @$vectorsDisplacementArea = $("<div class='vectors-displacement-area sub-panel'><div class='title'>Displacement</div></div>")
    @$vectorsArea.append(@$vectorsDisplacementArea)

    @vectorsDisplacementVectorControl = new TopViewer.VectorControl @,
      $parent: @$vectorsDisplacementArea
      saveState: saveState.vectors.displacementVector

    @$vectorsDisplacementArea.append("<p class='label'>Amplification</p>")
    @vectorsDisplacementFactorControl = new TopViewer.SliderControl @,
      $parent: @$vectorsDisplacementArea
      class: 'vectors-displacement-factor'
      minimumValue: 0
      maximumValue: 100
      power: 4
      decimals: -2
      value: saveState.vectors.displacementFactor
      onChange: (value) =>
        saveState.displacementFactor = value

    @$vectorsFieldArea = $("<div class='vectors-field-area sub-panel'><div class='title'>Vector field</div></div>")
    @$vectorsArea.append(@$vectorsFieldArea)

    @vectorsFieldVectorControl = new TopViewer.VectorControl @,
      $parent: @$vectorsFieldArea
      saveState: saveState.vectors.fieldVector

    @$vectorsFieldArea.append("<p class='label'>Unit length</p>")
    @vectorsFieldLengthControl = new TopViewer.SliderControl @,
      $parent: @$vectorsFieldArea
      class: 'vectors-field-length'
      minimumValue: 0
      maximumValue: 2
      power: 4
      decimals: -4
      value: saveState.vectors.fieldLength
      onChange: (value) =>
        saveState.vectors.fieldLength = value

    @vectorsFieldColorsControl = new TopViewer.VertexColorsControl @,
      $parent: @$vectorsFieldArea
      class: 'vectors-field-colors-selector'
      saveState: saveState.vectors.fieldColors

    @$vectorsFieldArea.append("<p class='label'>Opacity</p>")
    @vectorsFieldOpacityControl = new TopViewer.SliderControl @,
      $parent: @$vectorsFieldArea
      minimumValue: 0
      maximumValue: 1
      value: saveState.vectors.fieldOpacity
      decimals: -2
      onChange: (value) =>
        saveState.vectors.fieldOpacity = value

    @initialize()

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
    # Update scalar dropdowns.
    TopViewer.ScalarControl.addResults name, scalar

    $scalar = $("<li class='scalar'></li>")
    @$scalarsArea.append($scalar)

    $contents = $("<div>")

    new TopViewer.ToggleContainer @,
      $parent: $scalar
      text: name
      visible: true
      $contents: $contents

    # Add curve control for this scalar.
    states = @options.engine.options.app.state.renderingControls.scalars

    scalar.renderingControls =
      curveTransformControl: new TopViewer.CurveTransformControl @,
        $parent: $contents
        saveState: TopViewer.SaveState.findStateForName states, name
        scalar: scalar
        gradientControl: @gradientControl

  addVector: (name, vector) ->
    # Update vector dropdowns.
    TopViewer.VectorControl.addResults name, vector

  onMouseDown: (position, button) ->
    super

    TopViewer.CurveTransformControl.mouseDown @transformPositionToPage position

  onMouseMove: (position) ->
    super

    TopViewer.CurveTransformControl.mouseMove @transformPositionToPage position

  onMouseUp: (position, button) ->
    super

    TopViewer.CurveTransformControl.mouseUp @transformPositionToPage position

  transformPositionToPage: (position) ->
    offset = @$appWindow.offset()

    x: position.x + offset.left
    y: position.y + offset.top

  sync: (data) ->
    handler data for handler in @_syncHandlers

  _onSync: (handler) ->
    @_syncHandlers.push handler
