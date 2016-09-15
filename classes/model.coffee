'use strict'

###

  HOW TOP VIEWER SHADERS WORK

  Traditional way to render 3D models is to have a vertex buffer that holds positions of all vertices and an index
  buffer that tells which vertices the triangles are made out of.

  We, however, need to be able to create dynamic geometry for isolines and isosurfaces that depends on data from
  multiple vertices. For example, depending on a scalar value at two vertices of a mesh triangle, we will draw an
  isoline starting somewhere in the middle of the two vertices. To achieve this "random-access" behavior, we need
  to be able to address data from multiple vertices per each vertex.

  Under the traditional way, each index in the index buffer tells which vertex data to use. In our way, there is no
  traditional index buffer. Instead, index is stored in a vertex attribute, while vertex data (such as position or
  scalar value) are stored in data textures. Instead of thinking about fixed model vertices, each vertex in our system
  represents a dynamic vertex that can rely on multiple model vertices. The index, stored in an attribute, tells which
  vertex that is. If we need to access data from multiple vertices, we have multiple attributes. In the simplest case
  though, one index attribute simply points to the single data location, just like with a normal index buffer.

  Vertex data in the textures is stored in one of the 4096x4096 pixels with r/g/b components storing data, for example
  the x/y/z coordinates of the vertex, displacement vectors or scalar data. This allows us to display models with up to
  16 million vertices. Instead of a normal numerical index, index is broken to two components, the texture coordinates
  at which the vertex is located. The top row holds vertices 0-4095, second row vertices 4096-8191 and so on.

###

class TopViewer.Model extends THREE.Object3D
  # Create an empty scalar texture to be used when there are no scalars.
  @noScalarsTexture = new THREE.DataTexture new Float32Array(4096 * 4096), 4096, 4096, THREE.AlphaFormat, THREE.FloatType
  @noScalarsTexture.needsUpdate = true

  # Create an empty displacement texture to be used when there are no vectors.
  @noDisplacementsTexture = new THREE.DataTexture new Float32Array(4096 * 4096 * 3), 4096, 4096, THREE.RGBFormat, THREE.FloatType
  @noDisplacementsTexture.needsUpdate = true

  # Create an empty scalar texture to be used when there are no curves.
  @noCurveTexture = new THREE.DataTexture new Float32Array(4096), 4096, 1, THREE.AlphaFormat, THREE.FloatType, THREE.UVMapping, THREE.ClampToEdgeWrapping, THREE.ClampToEdgeWrapping, THREE.LinearFilter, THREE.LinearFilter
  @noCurveTexture.needsUpdate = true

  constructor: (@options) ->
    super

    @matrixAutoUpdate = false

    @nodes = @options.nodes

    @meshes = {}
    @volumes = {}
    @scalars = {}
    @vectors = {}

    @frames = [
      frameTime: -1
    ]

    @boundingBox = new THREE.Box3

    height = 1
    while @nodes.length / 3 > 4096 * height
      height *= 2

    @basePositions = new Float32Array 4096 * height * 3
    for i in [0...@nodes.length/3]
      for j in [0..2]
        @basePositions[i * 3 + j] = @nodes[i * 3 + j]

      @boundingBox.expandByPoint new THREE.Vector3 @nodes[i * 3], @nodes[i * 3 + 1], @nodes[i * 3 + 2]

    @boundingSphere = @boundingBox.getBoundingSphere()

    @basePositionsTexture = new THREE.DataTexture @basePositions, 4096, height, THREE.RGBFormat, THREE.FloatType
    @basePositionsTexture.needsUpdate = true

    # This is the basic material for rendering surfaces of meshes.
    @material = new TopViewer.ModelMaterial @

    # This is the inverted basic material that creates a surface on the opposite side.
    @backsideMaterial = new TopViewer.ModelMaterial @
    @backsideMaterial.side = THREE.BackSide
    @backsideMaterial.uniforms.lightingNormalFactor.value = -1

    # This is the shadow material for rendering meshes into the shadow depth buffer.
    @shadowMaterial = new TopViewer.ShadowMaterial @

    @wireframeMaterial = new TopViewer.WireframeMaterial @
    @isolineMaterial = new TopViewer.IsolineMaterial @

    @volumeWireframeMaterial = new TopViewer.WireframeMaterial @
    @isosurfaceMaterial = new TopViewer.IsosurfaceMaterial @

    @colorScalar = null

    # Add the model to the scene.
    @options.engine.scene.addModel @ if @nodes.length

    @_updateFrames()

    @_currentVectorFrames = {}

  addElements: (elementsName, elementsType, elements) ->
    switch elementsType
      when 4
        # Triangle (Tri_3)
        collection = @meshes
        constructor = TopViewer.Mesh

      when 5
        # Tetrahedron (Tetra_4)
        collection = @volumes
        constructor = TopViewer.Volume

      else
        console.error "UNKNOWN ELEMENT TYPE", elementsType
        return

    collection[elementsName] = new constructor
      name: elementsName
      elements: elements
      model: @
      engine: @options.engine
      
    @options.engine.scene.update()

  addScalar: (scalarName, scalar) ->
    # See if we already have this scalar or we're just getting new frames.
    if @scalars[scalarName]
      # Add new frames to the existing scalar.
      for frame in scalar.frames
        @scalars[scalarName].frames.push frame

      # Update the scalars histogram.
      @scalars[scalarName].renderingControls.curveTransformControl.updateHistogram()

    else
      # This is a new scalar.
      @scalars[scalarName] = scalar

      # Add scalar to controls.
      @options.engine.renderingControls.addScalar scalarName, scalar

    @_updateFrames()
    
    for frame in scalar.frames
      height = 1
      while frame.scalars.length > 4096 * height
        height *= 2

      array = new Float32Array 4096 * height
      array[i] = frame.scalars[i] for i in [0...frame.scalars.length]
      frame.texture = new THREE.DataTexture array, 4096, height, THREE.AlphaFormat, THREE.FloatType
      frame.texture.needsUpdate = true

  addVector: (vectorName, vector) ->
    # See if we already have this vector or we're just getting new frames.
    if @vectors[vectorName]
      # Add new frames to the existing vector.
      for frame in vector.frames
        @vectors[vectorName].frames.push frame

    else
      # This is a new vector.
      @vectors[vectorName] = vector

      # Add vector to controls.
      @options.engine.renderingControls.addVector vectorName, vector

    @_updateFrames()

    for frame in vector.frames
      height = 1
      while frame.vectors.length / 3 > 4096 * height
        height *= 2

      array = new Float32Array 4096 * height * 3
      array[i] = frame.vectors[i] for i in [0...frame.vectors.length]
      frame.texture = new THREE.DataTexture array, 4096, height, THREE.RGBFormat, THREE.FloatType
      frame.texture.needsUpdate = true

  _updateFrames: ->
    # Determine time frames.
    frameTimes = []

    for scalarName, scalar of @scalars
      for frame in scalar.frames
        frameTimes = _.union frameTimes, [parseFloat frame.time]

    for vectorName, vector of @vectors
      for frame in vector.frames
        frameTimes = _.union frameTimes, [parseFloat frame.time]

    frameTimes.sort (a, b) ->
      a - b

    @options.engine.animation.addFrameTimes frameTimes

    # Create a dummy frame if there's no scalar/vector information.
    frameTimes.push -1 unless frameTimes.length

    # Now create the frames using relevant scalars and vectors.
    @frames = []

    for frameTime in frameTimes
      newFrame =
        time: frameTime
        scalars: []
        vectors: []

      for scalarName, scalar of @scalars
        for i in [0...scalar.frames.length]
          scalarFrame = scalar.frames[i]
          continue unless frameTime is scalarFrame.time
          newFrame.scalars.push {scalarName, scalarFrame}

      for vectorName, vector of @vectors
        for vectorFrame in vector.frames
          continue unless frameTime is vectorFrame.time
          newFrame.vectors.push {vectorName, vectorFrame}

      @frames.push newFrame

  showFrame: (frameTime, nextFrameTime, frameProgress) ->
    # Find the frame and next frame for the given time. Frame with time -1 is always present.
    frame = null
    nextFrame = null

    for frameIndex in [0...@frames.length]
      testFrame = @frames[frameIndex]
      time = testFrame.time

      frame = testFrame if time is frameTime or time is -1
      nextFrame = testFrame if time is nextFrameTime or time is -1

    # Make sure we have a frame and the vertices are not empty (no triangles).
    @visible = frame and @nodes.length
    return unless @visible

    # In case we don't have the next frame, just use the same frame.
    nextFrame ?= frame

    renderingControls = @options.engine.renderingControls

    positionMaterials = [@material, @shadowMaterial, @wireframeMaterial, @volumeWireframeMaterial, @isolineMaterial, @isosurfaceMaterial]

    surfaceMaterials = [
      material: @material
      colorsControl: renderingControls.meshesSurfaceColorsControl
      opacityControl: renderingControls.meshesSurfaceOpacityControl
    ,
      material: @isosurfaceMaterial
      colorsControl: renderingControls.volumesIsosurfacesColorsControl
      opacityControl: renderingControls.volumesIsosurfacesOpacityControl
    ]

    wireframeMaterials = [
      material: @wireframeMaterial
      colorsControl: renderingControls.meshesWireframeColorsControl
      opacityControl: renderingControls.meshesWireframeOpacityControl
    ,
      material: @volumeWireframeMaterial
      colorsControl: renderingControls.volumesWireframeColorsControl
      opacityControl: renderingControls.volumesWireframeOpacityControl
    ]

    isovalueMaterials = [
      material: @isolineMaterial
      scalarControl: renderingControls.meshesIsolinesScalarControl
      colorsControl: renderingControls.meshesIsolinesColorsControl
      opacityControl: renderingControls.meshesIsolinesOpacityControl
    ,
      material: @isosurfaceMaterial
      scalarControl: renderingControls.volumesIsosurfacesScalarControl
      colorsControl: renderingControls.volumesIsosurfacesColorsControl
      opacityControl: renderingControls.volumesIsosurfacesOpacityControl
    ]

    # Determine the type of mesh surface rendering.
    switch renderingControls.meshesSurfaceSidesControl.value 
      when TopViewer.RenderingControls.MeshSurfaceSides.SingleFront
        # We only need the basic model material, set to front side.
        @material.side = THREE.FrontSide
        @material.uniforms.lightingNormalFactor.value = 1

      when TopViewer.RenderingControls.MeshSurfaceSides.SingleBack
        # We only need the basic model material, set to back side.
        @material.side = THREE.BackSide
        @material.uniforms.lightingNormalFactor.value = -1

      when TopViewer.RenderingControls.MeshSurfaceSides.DoubleFast
        # We only need the basic model material, set to double side.
        @material.side = THREE.DoubleSide
        @material.uniforms.lightingNormalFactor.value = 1

      when TopViewer.RenderingControls.MeshSurfaceSides.DoubleQuality
        # We need the basic model material, set to front side, and inverted set to back.
        @material.side = THREE.FrontSide
        @material.uniforms.lightingNormalFactor.value = 1
        positionMaterials.push @backsideMaterial
        surfaceMaterials.push
          material: @backsideMaterial
          colorsControl: renderingControls.meshesSurfaceColorsControl
          opacityControl: renderingControls.meshesSurfaceOpacityControl

    # Determine displacement vector.
    displacementsTexture = @constructor.noDisplacementsTexture
    displacementsTextureNext = @constructor.noDisplacementsTexture

    for vector in frame.vectors
      if @vectors[vector.vectorName] is renderingControls.displacementDropdown.value
        displacementsTexture = vector.vectorFrame.texture

    for vector in nextFrame.vectors
      if @vectors[vector.vectorName] is renderingControls.displacementDropdown.value
        displacementsTextureNext = vector.vectorFrame.texture

    # Setup all materials.
    for material in positionMaterials
      # Frame progress
      material.uniforms.frameProgress.value = frameProgress

      # Positions
      material.uniforms.displacementsTexture.value = displacementsTexture
      material.uniforms.displacementsTextureNext.value = displacementsTextureNext
      material.uniforms.displacementFactor.value = renderingControls.displacementFactor.value

      # Time
      time = performance.now() / 1000
      material.uniforms.time.value = time

    # Extra setup for surface materials.
    for surfaceMaterial in surfaceMaterials

      # Vertex colors
      switch surfaceMaterial.colorsControl.typeControl.value
        when TopViewer.RenderingControls.VertexColorsType.Color
          surfaceMaterial.material.uniforms.vertexColor.value = surfaceMaterial.colorsControl.colorControl.value
          surfaceMaterial.material.uniforms.vertexScalarsRange.value = 0

        when TopViewer.RenderingControls.VertexColorsType.Scalar
          selectedScalar = surfaceMaterial.colorsControl.scalarControl.value

          @_setupVertexScalars surfaceMaterial.material, selectedScalar, frame, nextFrame

      surfaceMaterial.material.uniforms.vertexScalarsGradientTexture.value = renderingControls.gradientControl.value.texture
      
      # Opacity
      surfaceMaterial.material.uniforms.opacity.value = surfaceMaterial.opacityControl.value
      surfaceMaterial.material.transparent = surfaceMaterial.material.uniforms.opacity.value isnt 1

      # Lighting
      surfaceMaterial.material.uniforms.lightingBidirectional.value = if renderingControls.bidirectionalLightControl.value then 1 else 0

    # Extra setup for wireframe materials.
    for wireframeMaterial in wireframeMaterials

      # Vertex colors
      switch wireframeMaterial.colorsControl.typeControl.value
        when TopViewer.RenderingControls.VertexColorsType.Color
          wireframeMaterial.material.uniforms.vertexColor.value = wireframeMaterial.colorsControl.colorControl.value
          wireframeMaterial.material.uniforms.vertexScalarsRange.value = 0

        when TopViewer.RenderingControls.VertexColorsType.Scalar
          selectedScalar = wireframeMaterial.colorsControl.scalarControl.value

          @_setupVertexScalars wireframeMaterial.material, selectedScalar, frame, nextFrame

      wireframeMaterial.material.uniforms.vertexScalarsGradientTexture.value = renderingControls.gradientControl.value.texture

      # Opacity
      wireframeMaterial.material.uniforms.opacity.value = wireframeMaterial.opacityControl.value
      wireframeMaterial.material.transparent = wireframeMaterial.material.uniforms.opacity.value isnt 1

    # Extra setup for isovalue materials.
    for isovalueMaterial in isovalueMaterials
      # Isovalue scalar
      selectedScalar = isovalueMaterial.scalarControl.value
      for scalar in frame.scalars
        scalarData = @scalars[scalar.scalarName]
        if scalarData is selectedScalar
          isovalueMaterial.material.uniforms.scalarsTexture.value = scalar.scalarFrame.texture
          isovalueMaterial.material.uniforms.scalarsCurveTexture.value = scalarData.renderingControls.curveTransformControl.curveTexture
          isovalueMaterial.material.uniforms.scalarsMin.value = scalarData.renderingControls.curveTransformControl.clip.min
          isovalueMaterial.material.uniforms.scalarsRange.value = scalarData.renderingControls.curveTransformControl.clip.max - scalarData.renderingControls.curveTransformControl.clip.min

      for scalar in nextFrame.scalars
        if @scalars[scalar.scalarName] is selectedScalar
          isovalueMaterial.material.uniforms.scalarsTextureNext.value = scalar.scalarFrame.texture

      # Vertex colors
      switch isovalueMaterial.colorsControl.typeControl.value
        when TopViewer.RenderingControls.VertexColorsType.Color
          isovalueMaterial.material.uniforms.vertexColor.value = isovalueMaterial.colorsControl.colorControl.value
          isovalueMaterial.material.uniforms.vertexScalarsRange.value = 0

        when TopViewer.RenderingControls.VertexColorsType.Scalar
          selectedScalar = isovalueMaterial.colorsControl.scalarControl.value

          @_setupVertexScalars isovalueMaterial.material, selectedScalar, frame, nextFrame

      isovalueMaterial.material.uniforms.vertexScalarsGradientTexture.value = renderingControls.gradientControl.value.texture

      # Opacity
      isovalueMaterial.material.uniforms.opacity.value = isovalueMaterial.opacityControl.value
      isovalueMaterial.material.transparent = isovalueMaterial.material.uniforms.opacity.value isnt 1

    # Display all objects.
    for collection in [@meshes, @volumes]
      for name, object of collection
        object.showFrame()

  _setupVertexScalars: (material, selectedScalar, frame, nextFrame) ->
    for scalar in frame.scalars
      scalarData = @scalars[scalar.scalarName]
      if scalarData is selectedScalar
        material.uniforms.vertexScalarsTexture.value = scalar.scalarFrame.texture
        material.uniforms.vertexScalarsCurveTexture.value = scalarData.renderingControls.curveTransformControl.curveTexture
        material.uniforms.vertexScalarsMin.value = scalarData.renderingControls.curveTransformControl.clip.min
        material.uniforms.vertexScalarsRange.value = scalarData.renderingControls.curveTransformControl.clip.max - scalarData.renderingControls.curveTransformControl.clip.min

    for scalar in nextFrame.scalars
      if @scalars[scalar.scalarName] is selectedScalar
        material.uniforms.vertexScalarsTextureNext.value = scalar.scalarFrame.texture
