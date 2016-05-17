'use strict'

class TopViewer.AnimationSet extends TopViewer.Animation
  constructor: (@options) ->
    super

    @loader = new THREE.TopLoader @options.loadingManager

    @files = []

    @objects =
      nodes: {}
      elements: {}
      vectors: {}
      scalars: {}

    @times = []

    @meshes = {}

    @loadGradient @options.resourcesPath + 'gradients/xpost.png'

  loadGradient: (url) ->
    image = new Image()
    image.onload = =>
      canvas = document.createElement('canvas')
      canvas.width = image.width
      canvas.height = 1
      canvas.getContext('2d').drawImage image, 0, 0, image.width, 1
      uintData = canvas.getContext('2d').getImageData(0, 0, image.width, 1).data
      @gradientData = new Float32Array uintData.length
      @gradientData[i] = uintData[i] / 255 for i in [0...uintData.length]

    image.src = url

  getFrameSet: (frameIndex) ->
    time = @times[frameIndex]

    frameSet = []

    # Add all frames from meshes.
    for nodesName, mesh of @meshes
      frame = mesh.getFrame time
      frameSet.push frame if frame

    frameSet

  normalizeMeshes: (forceNormalize, targetFrameSet) ->
    # We can simply defer to the default algorithm if all we need to do is normalize frames in the frame set.
    if targetFrameSet
      super forceNormalize, targetFrameSet, @referenceMesh

    else
      # We need to normalize all the meshes.
      for nodesName, mesh of @meshes
        console.log "norm", @meshes
        # We already have a reference to normalize to, so pass it along.
        mesh.normalizeMeshes forceNormalize, targetFrameSet, @referenceMesh

  load: ->
    @options.playbackControls.load()

    for filename in @options.filenames
      file =
        loaded: false
        loadPercentage: 0
        filename: filename

      @files.push file

    @_nextFileToLoad = 0
    @_filesLoaded = 0
    @_concurentFramesLoading = 0
    @processLoadQueue()

  processLoadQueue: ->
    return unless @_nextFileToLoad?

    # Stop if loading is paused.
    return unless @options.playbackControls.loading

    # Stop when we reach the end of the frames.
    return if @_nextFileToLoad >= @files.length

    # Don't load if we're at the limit of concurrent loads.
    return if @maxConcurrentFramesLoading and @_concurentFramesLoading >= @maxConcurrentFramesLoading

    file = @files[@_nextFileToLoad]

    console.log "Loading", file.filename, @loader

    @loader.load file.filename, (objects) =>
      @_filesLoaded++

      # Add nodes.
      for nodesName, nodesInstance of objects.nodes
        @objects.nodes[nodesName] = nodesInstance

      # Add elements.
      for elementsName, elementsInstance of objects.elements
        @objects.elements[elementsName] = elementsInstance

      # Add all scalars.
      for scalarNodesName, scalars of objects.scalars
        @objects.scalars[scalarNodesName] ?= {}
        for scalarName, scalar of scalars
          @objects.scalars[scalarNodesName][scalarName] = scalar

      # Add all vectors.
      for vectorNodesName, vectors of objects.vectors
        @objects.vectors[vectorNodesName] ?= {}
        for vectorName, vector of vectors
          @objects.vectors[vectorNodesName][vectorName] = vector

      # Process all the objects once we've loaded all the files.
      @processObjects() if @_filesLoaded is @files.length

      # We have completed loading this frame so try to load a new one.
      @_concurentFramesLoading--
      @processLoadQueue()
    ,
      (loadPercentage) =>
        #console.log file.filename, "loaded", loadPercentage

    # Increment frames.
    @_nextFileToLoad++
    @_concurentFramesLoading++

    # Keep on loading so we hit the concurrency limit.
    @processLoadQueue()

  processObjects: ->
    console.log "PROCESSING OBJECTS!", @options, @objects

    # Create all the meshes from nodes.
    for nodesName, nodesInstance of @objects.nodes
      #console.log "creating mesh for", nodesName, nodesInstance
      @meshes[nodesName] = new @constructor.Mesh nodesName, nodesInstance, @

    # Add element information to meshes
    for elementsName, elementsInstance of @objects.elements
      @meshes[elementsInstance.nodesName].addElements elementsName, elementsInstance

    # Calculate global min/max of scalar values.
    limits = {}

    for scalarNodesName, scalars of @objects.scalars
      for scalarName, scalar of scalars
        limits[scalarName] ?= {}

        for frame in scalar.frames
          limits[scalarName].minValue = frame.minValue unless limits[scalarName].minValue? and limits[scalarName].minValue < frame.minValue
          limits[scalarName].maxValue = frame.maxValue unless limits[scalarName].maxValue? and limits[scalarName].maxValue > frame.maxValue

    # Add all scalars.
    for scalarNodesName, scalars of @objects.scalars
      for scalarName, scalar of scalars
        scalar.minValue = limits[scalarName].minValue
        scalar.maxValue = limits[scalarName].maxValue
        @meshes[scalarNodesName].addScalar scalarName, scalar

    # Add all vectors.
    for vectorNodesName, vectors of @objects.vectors
      for vectorName, vector of vectors
        @meshes[vectorNodesName].addVector vectorName, vector

    # Find a mesh frame to normalize to.
    @referenceMesh = null

    for nodesName, mesh of @meshes
      mesh.createFrames()
      mesh.normalizeMeshes()

      if not @referenceMesh and mesh.frames[0]?.normalized
        @referenceMesh = mesh
        console.log "Set reference mesh to", @referenceMesh

    # Normalize all to reference.
    for nodesName, mesh of @meshes
        mesh.normalizeMeshes true, null, @referenceMesh

    # Collect frame times.
    @times = []

    for nodesName, mesh of @meshes
      @times = _.union @times, mesh.times

    @times.sort (a, b) ->
      a - b

    @times = _.without @times, -1

    # Create a dummy frame if there's no scalar/vector information.
    @times.push -1 unless @times.length

    # Set animation length.
    @length = @times.length

    console.log "We have an animation of", @length, "length and times", @times

    # We are now ready to begin drawing the complete animation.
    @ready = true
    @readyLength = @length

  class @Mesh extends TopViewer.Animation
    constructor: (@nodesName, @nodesInstance, @animation) ->
      super @animation.options

      @elements = {}
      @scalars = {}
      @vectors = {}

      @_currentScalarFrame = null
      @_gradientMap = []
      @_gradientMapLastUpdate = null

      @_currentDisplacementFactor = null
      @_currentPositions = null
      @_paintedWhite = false

    addElements: (elementsName, elementsInstance) ->
      @elements[elementsName] = elementsInstance

    addScalar: (scalarName, scalar) ->
      @scalars[scalarName] = scalar
      #console.log "Added scalar", scalar

    addVector: (vectorName, vector) ->
      @vectors[vectorName] = vector
      #console.log "Added vector", vector

    getFrame: (frameTime) ->
      # Find the frame for the given time. Frame with time -1 is always present.
      frame = null

      #Due to base frame at index 0, our real frames start at index 1.
      for frameIndex in [1...@frames.length]
        testFrame = @frames[frameIndex]
        continue unless testFrame

        time = testFrame.time
        frame = testFrame if time is frameTime or time is -1

      return unless frame

      # Make sure we have a frame and the vertices are not empty (no triangles).
      return unless frame and frame.positions.length

      positions = frame.positions
      displacedPositions = frame.displacedPositions
      colors = frame.colors
      scalarFrame = frame.scalarFrame
      vectorFrame = frame.vectorFrame

      #console.log "got frame for time", frameTime, scalarFrame, vectorFrame

      # Create colors.
      if scalarFrame and @animation.gradientData

        # We must repaint if we're white (no colors) or if colors come from another frame.
        mustRepaint = @_paintedWhite or @_currentScalarFrame isnt scalarFrame

        # Recreate the gradient map if it has changed.
        unless @_gradientMapLastUpdate is @animation.options.renderingControls.gradientCurve.lastUpdated
          @_gradientMapLastUpdate = @animation.options.renderingControls.gradientCurve.lastUpdated
          mustRepaint = true
          '''
          for i in [0..100]
            normalizedValue = i/100

            # Remap the value based on the gradient curve.
            normalizedValue = @animation.options.renderingControls.gradientCurve.getY normalizedValue

            # Set the gradient index into the map.
            @_gradientMap[i] = Math.floor((@animation.gradientData.length / 4 - 1) * normalizedValue) * 4

          console.log "recreated gradient", @_gradientMap
          '''

        if mustRepaint
          normalizeFactor = 1 / (frame.scalarMaxValue - frame.scalarMinValue)

          for i in [0...scalarFrame.scalars.length]
            value = scalarFrame.scalars[i]
            normalizedValue = (value - frame.scalarMinValue) * normalizeFactor

            # Remap the value based on the gradient curve.
            normalizedValue = @animation.options.renderingControls.gradientCurve.getY normalizedValue

            # Set the gradient index into the map.
            gradientIndex = Math.floor((@animation.gradientData.length / 4 - 1) * normalizedValue) * 4

            #gradientIndex = @_gradientMap[Math.floor normalizedValue * 100]
            colors[i * 3 + offset] = @animation.gradientData[gradientIndex + offset] for offset in [0..2]

          @_paintedWhite = false
          @_currentScalarFrame = scalarFrame
          @geometry.attributes.color.needsUpdate = true

      else
        # If there're no scalar values, make the model white (unless it's already white).
        unless @_paintedWhite
          for i in [0...colors.length]
            colors[i] = 1

          @_paintedWhite = true
          @geometry.attributes.color.needsUpdate = true

      # Displace positions
      if vectorFrame
        unless @_currentDisplacementFactor is @animation.options.renderingControls.displacementFactor and @_currentPositions is positions
          @_currentPositions = positions

          for i in [0...positions.length]
            displacedPositions[i] = positions[i] + vectorFrame.vectors[i] * @animation.options.renderingControls.displacementFactor

      else
        # Simply copy the original positions.
        unless @_currentPositions is positions
          @_currentPositions = positions

          for i in [0...positions.length]
            displacedPositions[i] = positions[i]

      @geometry.attributes.position.needsUpdate = true
      @geometry.computeVertexNormals()
      @geometry.computeBoundingSphere()
      @geometry.computeBoundingBox()

      # Return the first frame as that's the one added to the scene.
      @frames[1]

    createFrames: ->
      #console.log "Preparing mesh for nodes", @nodesName

      # Determine time frames.
      @times = []

      for scalarName, scalar of @scalars
        for frame in scalar.frames
          @times = _.union @times, [parseFloat frame.time]

      for vectorName, vector of @vectors
        for frame in vector.frames
          @times = _.union @times, [parseFloat frame.time]

      @times.sort (a, b) ->
        a - b

      # Create a dummy frame if there's no scalar/vector information.
      @times.push -1 unless @times.length

      # Set animation length.
      @length = @times.length

      #console.log "Animation times", @times

      # Prepare positions.
      positions = @nodesInstance.nodes

      # Create indices if necessary.
      totalIndices = 0
      for elementsName, elementsInstance of @elements
        totalIndices += elementsInstance.elements.length

      #console.log "We have", totalIndices, "indices."

      if totalIndices
        indices = new Uint32Array totalIndices

        indicesOffset = 0
        for elementsName, elementsInstance of @elements
          indicesCount = elementsInstance.elements.length
          for j in [0...indicesCount]
            indices[indicesOffset + j] = elementsInstance.elements[j]

          indicesOffset += indicesCount

      # Prepare the base geometry and mesh.
      @baseGeometry = new THREE.BufferGeometry()
      @baseGeometry.addAttribute 'position', new THREE.BufferAttribute positions, 3
      @baseGeometry.setIndex new THREE.BufferAttribute indices, 1 if totalIndices
      @baseGeometry.computeVertexNormals()
      @baseGeometry.computeBoundingSphere()
      @baseGeometry.computeBoundingBox()

      @baseMesh = new THREE.Mesh @baseGeometry, @animation.options.scene.modelMaterial
      @baseMesh.matrixAutoUpdate = false

      @baseFrame =
        mesh: @baseMesh
        loaded: true
        ready: true

      # Base frame will be frame 0 and will act as normalization reference for other frames.
      @frames.push @baseFrame

      #console.log "Created base model vertices and indices", @baseGeometry

      # Prepare tha displayed geometry and mesh. Positions refer to the base (non-displaced) positions so we need a new
      # array that will hold the current (displaced) positions for the mesh. Colors on the other hand are always
      # dynamically recomputed from the scalar values.
      displacedPositions = positions.slice(0)
      colors = new Float32Array positions.length

      @geometry = new THREE.BufferGeometry()
      @geometry.addAttribute 'position', new THREE.BufferAttribute displacedPositions, 3
      @geometry.addAttribute 'color', new THREE.BufferAttribute colors, 3
      @geometry.setIndex new THREE.BufferAttribute indices, 1 if totalIndices
      @geometry.computeVertexNormals()
      @geometry.computeBoundingSphere()
      @geometry.computeBoundingBox()

      @mesh = new THREE.Mesh @geometry, @animation.options.scene.modelMaterial
      @mesh.matrixAutoUpdate = false
      @mesh.castShadow = true

      # Now create the frames using the base and relevant scalars and vectors.
      for time in @times
        newFrame =
          mesh: @mesh
          time: time
          positions: positions
          displacedPositions: displacedPositions
          colors: colors
          loaded: true
          ready: true
          normalized: true

        for scalarName, scalar of @scalars
          for i in [0...scalar.frames.length]
            scalarFrame = scalar.frames[i]
            continue unless time is scalarFrame.time

            newFrame.scalarFrame = scalarFrame
            newFrame.scalarMinValue = scalar.minValue
            newFrame.scalarMaxValue = scalar.maxValue

        for vectorName, vector of @vectors
          for vectorFrame in vector.frames
            continue unless time is vectorFrame.time

            newFrame.vectorFrame = vectorFrame

        @frames.push newFrame

      #console.log "made frames", @frames

      # We will use the first non-base frame as the frame added to the scene.
      @frames[1].normalized = false

      @animation.options.scene.addFrame @frames[1]

      # We are now ready to begin drawing the complete animation.
      @ready = true
      @readyLength = @length

      @onUpdated() if @onUpdated
