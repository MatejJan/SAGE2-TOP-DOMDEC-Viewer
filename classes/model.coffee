'use strict'

class TopViewer.Model extends THREE.Object3D
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

    # Create an empty scalar texture if there are no scalars.
    @scalarsTexture = new THREE.DataTexture new Float32Array(4096 * 4096 * 3), 4096, 4096, THREE.AlphaFormat, THREE.FloatType
    @scalarsTexture.needsUpdate = true

    # Create an empty displacement texture if there are no vectors.
    @displacementsTexture = new THREE.DataTexture new Float32Array(4096 * 4096 * 3), 4096, 4096, THREE.RGBFormat, THREE.FloatType
    @displacementsTexture.needsUpdate = true

    @material = new TopViewer.ModelMaterial @

    @wireframeMaterial = new TopViewer.ModelMaterial @
    @wireframeMaterial.uniforms.opacity.value = 0.3
    @wireframeMaterial.transparent = true

    @isolineMaterial = new TopViewer.IsolineMaterial @
    @isolineMaterial.uniforms.opacity.value = 0.9
    @isolineMaterial.transparent = true

    @isosurfaceMaterial = new TopViewer.IsosurfaceMaterial @
    @isosurfaceMaterial.uniforms.opacity.value = 0.9
    @isosurfaceMaterial.transparent = true

    @displacementVector = null
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

  addScalar: (scalarName, scalar) ->
    @scalars[scalarName] = scalar
    @_updateFrames()
    
    for frame in scalar.frames
      height = 1
      while frame.scalars.length > 4096 * height
        height *= 2

      array = new Float32Array 4096 * height
      array[i] = frame.scalars[i] for i in [0...frame.scalars.length]
      frame.texture = new THREE.DataTexture array, 4096, height, THREE.AlphaFormat, THREE.FloatType
      frame.texture.needsUpdate = true

    @colorScalar ?= scalar

  addVector: (vectorName, vector) ->
    @vectors[vectorName] = vector
    @_updateFrames()

    for frame in vector.frames
      height = 1
      while frame.vectors.length / 3 > 4096 * height
        height *= 2

      array = new Float32Array 4096 * height * 3
      array[i] = frame.vectors[i] for i in [0...frame.vectors.length]
      frame.texture = new THREE.DataTexture array, 4096, height, THREE.RGBFormat, THREE.FloatType
      frame.texture.needsUpdate = true

    @options.engine.renderingControls.addVector vectorName, vector

    @displacementVector ?= vector

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

  showFrame: (frameTime) ->
    # Find the frame for the given time. Frame with time -1 is always present.
    frame = null

    for frameIndex in [0...@frames.length]
      testFrame = @frames[frameIndex]

      time = testFrame.time
      frame = testFrame if time is frameTime or time is -1

    # Make sure we have a frame and the vertices are not empty (no triangles).
    @visible = frame and @nodes.length
    return unless @visible

    renderingControls = @options.engine.renderingControls

    # Create colors.
    for scalar in frame.scalars
      scalarData = @scalars[scalar.scalarName]
      if scalarData is @colorScalar
        @material.uniforms.scalarsTexture.value = scalar.scalarFrame.texture
        @material.uniforms.scalarsMin.value = scalarData.limits.minValue
        @material.uniforms.scalarsRange.value = scalarData.limits.maxValue - scalarData.limits.minValue

        @isolineMaterial.uniforms.scalarsTexture.value = scalar.scalarFrame.texture
        @isolineMaterial.uniforms.scalarsMin.value = scalarData.limits.minValue
        @isolineMaterial.uniforms.scalarsRange.value = scalarData.limits.maxValue - scalarData.limits.minValue

        @isosurfaceMaterial.uniforms.scalarsTexture.value = scalar.scalarFrame.texture
        @isosurfaceMaterial.uniforms.scalarsMin.value = scalarData.limits.minValue
        @isosurfaceMaterial.uniforms.scalarsRange.value = scalarData.limits.maxValue - scalarData.limits.minValue

    # Displace positions
    for vector in frame.vectors
      if @vectors[vector.vectorName] is @displacementVector
        @material.uniforms.displacementFactor.value = renderingControls.displacementFactor.value
        @material.uniforms.displacementsTexture.value = vector.vectorFrame.texture

        @wireframeMaterial.uniforms.displacementFactor.value = renderingControls.displacementFactor.value
        @wireframeMaterial.uniforms.displacementsTexture.value = vector.vectorFrame.texture

        @isolineMaterial.uniforms.displacementFactor.value = renderingControls.displacementFactor.value
        @isolineMaterial.uniforms.displacementsTexture.value = vector.vectorFrame.texture

        @isosurfaceMaterial.uniforms.displacementFactor.value = renderingControls.displacementFactor.value
        @isosurfaceMaterial.uniforms.displacementsTexture.value = vector.vectorFrame.texture

    time = performance.now() / 1000
    @material.uniforms.time.value = time
    @wireframeMaterial.uniforms.time.value = time
    @isolineMaterial.uniforms.time.value = time

    for collection in [@meshes, @volumes]
      for name, object of collection
        object.showFrame()
