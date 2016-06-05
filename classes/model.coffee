'use strict'

class TopViewer.Model extends THREE.Object3D
  constructor: (@options) ->
    super

    @matrixAutoUpdate = false

    @nodes = @options.nodes

    @meshes = {}
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



    @_updateFrames()

  addElements: (elementsName, elementsInstance) ->
    @meshes[elementsName] = new TopViewer.Mesh
      name: elementsName
      elements: elementsInstance.elements
      model: @
      engine: @options.engine

  addScalar: (scalarName, scalar) ->
    @scalars[scalarName] = scalar
    @_updateFrames()

  addVector: (vectorName, vector) ->
    @vectors[vectorName] = vector
    @_updateFrames()

    @options.engine.renderingControls.addVector vectorName, vector

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
        vectors: []

      for scalarName, scalar of @scalars
        for i in [0...scalar.frames.length]
          scalarFrame = scalar.frames[i]
          continue unless frameTime is scalarFrame.time

      for vectorName, vector of @vectors
        for vectorFrame in vector.frames
          continue unless frameTime is vectorFrame.time

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
      # Repaint the colors if the gradient map has changed.
    for vector in frame.vectors




    for meshName, mesh of @meshes
      mesh.showFrame()
