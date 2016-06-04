'use strict'

class TopViewer.Model extends THREE.Object3D
  constructor: (@options) ->
    super

    @matrixAutoUpdate = false

    @nodes = @options.nodes

    @positions = null
    @colors = null
    @positionAttribute = null
    @colorAttribute = null

    @meshes = {}
    @scalars = {}
    @vectors = {}

    @frames = [
      frameTime: -1
    ]

    # Create positions.
    @positions = @nodes.slice()
    @positionAttribute = new THREE.BufferAttribute @positions, 3

    # Create colors
    @colors = new Float32Array @positions.length
    @colorAttribute = new THREE.BufferAttribute @colors, 3

    # Add the model to the scene. Parent must be explicitly set to null.
    @options.engine.scene.addModel @ if @positions.length

    @_updateFrames()

  addElements: (elementsName, elementsInstance) ->
    @meshes[elementsName] = new TopViewer.Mesh
      name: elementsName
      positionAttribute: @positionAttribute
      colorAttribute: @colorAttribute
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

          newFrame.scalarName = scalarName
          newFrame.scalarFrame = scalarFrame

      for vectorName, vector of @vectors
        for vectorFrame in vector.frames
          continue unless frameTime is vectorFrame.time

          newFrame.vectors.push
            vectorName: vectorName
            vectorFrame: vectorFrame

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
    if frame.scalarFrame and @options.engine.gradientData

      # We must repaint if we're white (no colors) or if colors come from another frame.
      mustRepaint = @_paintedWhite or @_currentScalarFrame isnt frame.scalarFrame

      # Repaint the colors if the gradient map has changed.
      unless @_gradientMapLastUpdate is renderingControls.gradientCurve.lastUpdated
        @_gradientMapLastUpdate = renderingControls.gradientCurve.lastUpdated
        mustRepaint = true

      # Repaint when limits have changed.
      scalar = @scalars[frame.scalarName]

      mustRepaint = true unless scalar._limitsVersion is scalar.limits.version

      if mustRepaint
        range = scalar.limits.maxValue - scalar.limits.minValue
        normalizeFactor = if range then 1 / range else 1
        gradientData = @options.engine.gradientData

        for i in [0...frame.scalarFrame.scalars.length]
          value = frame.scalarFrame.scalars[i]
          normalizedValue = (value - scalar.limits.minValue) * normalizeFactor

          # Remap the value based on the gradient curve.
          normalizedValue = renderingControls.gradientCurve.getY normalizedValue

          # Set the gradient index into the map.
          gradientIndex = Math.floor((gradientData.length / 4 - 1) * normalizedValue) * 4

          @colors[i * 3 + offset] = gradientData[gradientIndex + offset] for offset in [0..2]

        @_paintedWhite = false
        @_currentScalarFrame = frame.scalarFrame
        scalar._limitsVersion = scalar.limits.version
        @colorAttribute.needsUpdate = true

    else
      # If there're no scalar values, make the model white (unless it's already white).
      unless @_paintedWhite
        for i in [0...@colors.length]
          @colors[i] = 1

        @_paintedWhite = true
        @colorAttribute.needsUpdate = true

    # Displace positions, first copy the original positions.
    for i in [0...@positions.length]
      @positions[i] = @nodes[i]

    @positionAttribute.needsUpdate = true

    for vector in frame.vectors
      if vector.vectorFrame
        displacementFactor = @vectors[vector.vectorName].renderingControls.displacementFactor.value

        unless @_currentDisplacementFactor is displacementFactor and @_currentVectorFrame is frame.vectorFrame
          @_currentVectorFrame = vector.vectorFrame
          @_currentDisplacementFactor = displacementFactor

          for i in [0...@nodes.length]
            @positions[i] += vector.vectorFrame.vectors[i] * displacementFactor

          @positionAttribute.needsUpdate = true

    for meshName, mesh of @meshes
      mesh.showFrame()

