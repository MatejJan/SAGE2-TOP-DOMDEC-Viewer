'use strict'

class TopViewer.Mesh extends THREE.Mesh
  constructor: (@options) ->
    super new THREE.BufferGeometry(), @options.engine.scene.modelMaterial

    @matrixAutoUpdate = false

    @nodes = null
    @indices = null
    @positions = null
    @colors = null
    @scalars = {}
    @vectors = {}
    @frames = [
      frameTime: -1
    ]

  setNodes: (nodesInstance) ->
    # Create positions.
    @nodes = nodesInstance.nodes
    @positions = @nodes.slice()
    @geometry.addAttribute 'position', new THREE.BufferAttribute @positions, 3
    @_updateGeometry()

    # Now that we have positions, add the mesh to the scene.
    @options.engine.scene.addMesh @ if @positions.length

    # Create colors
    @colors = new Float32Array @positions.length
    @geometry.addAttribute 'color', new THREE.BufferAttribute @colors, 3

    @_updateGeometry()
    @_updateFrames()

  count = 0

  addElements: (elementsInstance) ->
    count++

    if @indices

      # We already have indices, extend them by the new size.
      oldIndices = @indices
      @indices = new Uint32Array oldIndices.length + elementsInstance.elements.length

      # First copy the existing indices.
      @indices[i] = oldIndices[i] for i in [0...oldIndices.length]

      # Now copy the new indices to the end.
      @indices[oldIndices.length + i] = elementsInstance.elements[i] for i in [0...elementsInstance.elements.length]

    else
      # We don't have indices yet, simply borrow the array buffer from the elements instance.
      @indices = elementsInstance.elements

    @geometry.setIndex new THREE.BufferAttribute @indices, 1

    # HACK: Clear groups so that normal computation in update geometry will work on the new indices.
    @geometry.clearGroups()

    @_updateGeometry()
    @_updateFrames()

  addScalar: (scalarName, scalar) ->
    @scalars[scalarName] = scalar
    @_updateFrames()

  addVector: (vectorName, vector) ->
    @vectors[vectorName] = vector
    @_updateFrames()

  _updateGeometry: ->
    @geometry.computeVertexNormals()
    @geometry.computeBoundingSphere()
    @geometry.computeBoundingBox()

    @options.engine.scene.acommodateMeshBounds @

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

      for scalarName, scalar of @scalars
        for i in [0...scalar.frames.length]
          scalarFrame = scalar.frames[i]
          continue unless frameTime is scalarFrame.time

          newFrame.scalarName = scalarName
          newFrame.scalarFrame = scalarFrame

      for vectorName, vector of @vectors
        for vectorFrame in vector.frames
          continue unless frameTime is vectorFrame.time

          newFrame.vectorName = vectorName
          newFrame.vectorFrame = vectorFrame

      @frames.push newFrame

  showFrame: (frameTime) ->
    # Find the frame for the given time. Frame with time -1 is always present.
    frame = null

    for frameIndex in [0...@frames.length]
      testFrame = @frames[frameIndex]

      time = testFrame.time
      frame = testFrame if time is frameTime or time is -1

    # Make sure we have a frame and the vertices are not empty (no triangles).
    unless frame and @nodes.length
      @visible = false
      @wireframeMesh?.visible = false
      return

    wireframe = @options.engine.renderingControls.wireframeControl.value

    # Create wireframe mesh if needed.
    if wireframe and not @wireframeMesh
      @wireframeMesh = new THREE.Mesh @geometry, @options.engine.scene.wireframeMaterial
      @wireframeMesh.matrixAutoUpdate = false
      @wireframeMesh.matrix = @matrix
      @options.engine.scene.add @wireframeMesh

    @visible = true
    @wireframeMesh?.visible = wireframe

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
        @geometry.attributes.color.needsUpdate = true

    else
      # If there're no scalar values, make the model white (unless it's already white).
      unless @_paintedWhite
        for i in [0...@colors.length]
          @colors[i] = 1

        @_paintedWhite = true
        @geometry.attributes.color.needsUpdate = true

    # Displace positions
    if frame.vectorFrame
      displacementFactor = renderingControls.displacementFactor

      unless @_currentDisplacementFactor is displacementFactor and @_currentVectorFrame is frame.vectorFrame
        @_currentVectorFrame = frame.vectorFrame
        @_currentDisplacementFactor = displacementFactor

        for i in [0...@nodes.length]
          @positions[i] = @nodes[i] + frame.vectorFrame.vectors[i] * displacementFactor

    else
      # Simply copy the original positions.
      unless @_currentVectorFrame is frame.vectorFrame
        @_currentVectorFrame = frame.vectorFrame

        for i in [0...@positions.length]
          @positions[i] = @nodes[i]

    @geometry.computeVertexNormals()
    @geometry.attributes.position.needsUpdate = true
