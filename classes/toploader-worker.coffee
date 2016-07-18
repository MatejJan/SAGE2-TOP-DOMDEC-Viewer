'use strict'

importScripts '../libraries/three.min.js'

self.onmessage = (message) ->
  url = message.data.url
  loader = new THREE.XHRLoader
  loader.setResponseType 'text'

  loadStart = new Date()

  loader.load url, (data) =>
    loadEnd = new Date()
    loadTime = loadEnd - loadStart #ms
    #console.log "Loaded in #{loadTime}ms", url

    processStart = new Date()
    worker = new TopWorker()
    objects = worker.parse data, url
    processEnd = new Date()
    processTime = processEnd - processStart #ms
    #console.log "Processed in #{processTime}ms", url

    postMessage
      type: 'result'
      objects: objects

    close()

class TopWorker
  parse: (data, url) ->
    lines = data.match /[^\r\n]+/g

    @_totalLines = lines.length
    @_percentageChangeAt = Math.floor @_totalLines / 100
    @_completedLines = 0

    #console.log "Parsing top file with length #{data.length} chars, #{lines.length} lines.", url

    nodes = {}
    currentNodesName = null
    currentNodes = null

    elements = {}
    currentElementsName = null
    currentElements = null

    vectors = {}
    currentVectorNodesName = null
    currentVectorName = null
    currentVector = null
    scalars = {}
    currentScalarNodesName = null
    currentScalarName = null
    currentScalar = null

    currentFrame = null
    currentFrameTime = null
    currentFrameNodesCount = null
    currentFrameNodeIndex = null

    modes =
      Nodes: 'Nodes'
      Elements: 'Elements'
      VectorCount: 'VectorCount'
      VectorTime: 'VectorTime'
      Vector: 'Vector'
      ScalarCount: 'ScalarCount'
      ScalarTime: 'ScalarTime'
      Scalar: 'Scalar'

    currentMode = null

    for line in lines
      # Split by whitespace.
      parts = line.match /\S+/g

      # Detect modes.
      switch parts[0]
        when 'Nodes'
          currentMode = modes.Nodes

          # Parse nodes header.
          currentNodesName = parts[1]
          currentNodes =
            nodes: []

          nodes[currentNodesName] = currentNodes
          continue

        when 'Elements'
          currentMode = modes.Elements

          # Parse elements header.
          currentElementsName = parts[1]
          currentElements =
            elements: {}
            nodesName: parts[3]

          elements[currentElementsName] = currentElements
          continue

        when 'Vector'
          currentMode = modes.VectorCount

          # Parse vector header.
          currentVectorNodesName = parts[5]
          currentVectorName = parts[1]
          currentVector =
            vectorName: parts[1]
            nodesName: parts[5]
            frames: []

          vectors[currentVectorNodesName] ?= {}
          vectors[currentVectorNodesName][currentVectorName] = currentVector
          continue

        when 'Scalar'
          currentMode = modes.ScalarCount

          # Parse scalars header.
          currentScalarNodesName = parts[5]
          currentScalarName = parts[1]
          currentScalar =
            scalarName: parts[1]
            nodesName: parts[5]
            frames: []

          scalars[currentScalarNodesName] ?= {}
          scalars[currentScalarNodesName][currentScalarName] = currentScalar
          continue

      # No mode switch was detected, continue business as usual.
      switch currentMode
        when modes.Nodes
          # Parse node.
          vertexIndex = parseInt parts[0]
          vertex =
            x: parseFloat parts[1]
            y: parseFloat parts[2]
            z: parseFloat parts[3]

          currentNodes.nodes[vertexIndex] = vertex

        when modes.Elements
          # Parse element.
          elementIndex = parseInt parts[0]
          elementType = parseInt parts[1]
          currentElements.elements[elementType] ?= []

          # Note: Vertex indices (1-4) based on TOP/DOMDEC User's Manual.
          switch elementType
            when 4
              # Triangle (Tri_3)
              newElement = [
                parseInt parts[2]
                parseInt parts[3]
                parseInt parts[4]
              ]
            when 5
              # Tetrahedron (Tetra_4)
              newElement = [
                parseInt parts[2]
                parseInt parts[3]
                parseInt parts[4]
                parseInt parts[5]
              ]
            else
              console.error "UNKNOWN ELEMENT TYPE", elementType

          currentElements.elements[elementType].push newElement

        when modes.VectorCount
          # Read number of nodes.
          currentFrameNodesCount = parseInt parts[0]
          currentMode = modes.VectorTime

        when modes.VectorTime
          # Read frame time.
          currentFrameTime = parseFloat parts[0]
          currentMode = modes.Vector

          currentFrame =
            time: currentFrameTime
            vectors: new Float32Array currentFrameNodesCount * 3

          currentVector.frames.push currentFrame

          currentFrameNodeIndex = 0

        when modes.Vector
          currentFrame.vectors[currentFrameNodeIndex * 3] = parseFloat parts[0]
          currentFrame.vectors[currentFrameNodeIndex * 3 + 1] = parseFloat parts[1]
          currentFrame.vectors[currentFrameNodeIndex * 3 + 2] = parseFloat parts[2]
          currentFrameNodeIndex++
          currentMode = modes.VectorTime if currentFrameNodeIndex is currentFrameNodesCount

        when modes.ScalarCount
          # Read number of nodes.
          currentFrameNodesCount = parseInt parts[0]
          currentMode = modes.ScalarTime

        when modes.ScalarTime
          # Read frame time.
          currentFrameTime = parseFloat parts[0]
          currentMode = modes.Scalar

          currentFrame =
            time: currentFrameTime
            scalars: new Float32Array currentFrameNodesCount
            minValue: null
            maxValue: null

          currentScalar.frames.push currentFrame

          currentFrameNodeIndex = 0

        when modes.Scalar
          value = parseFloat parts[0]
          currentFrame.minValue = value unless currentFrame.minValue? and currentFrame.minValue < value
          currentFrame.maxValue = value unless currentFrame.maxValue? and currentFrame.maxValue > value

          currentFrame.scalars[currentFrameNodeIndex] = value
          currentFrameNodeIndex++
          currentMode = modes.ScalarTime if currentFrameNodeIndex is currentFrameNodesCount

      @reportProgress()

    # Replace node and element arrays with array buffers.
    for nodesName, nodesInstance of nodes
      length = Math.max 0, nodesInstance.nodes.length - 1
      buffer = new Float32Array length * 3

      for i in [0...length]
        # Convert to 0-based indices.
        buffer[i*3] = nodesInstance.nodes[i+1].x
        buffer[i*3+1] = nodesInstance.nodes[i+1].y
        buffer[i*3+2] = nodesInstance.nodes[i+1].z

      nodesInstance.nodes = buffer

    nodesPerElement =
      "4": 3
      "5": 4

    for elementsName, elementsInstance of elements
      for elementsType, elementsList of elementsInstance.elements
        elementSize = nodesPerElement[elementsType]
        buffer = new Uint32Array elementsList.length * elementSize
        for i in [0...elementsList.length]
          for j in [0...elementSize]
            # Convert to 0-based indices.
            buffer[i*elementSize+j] = elementsList[i][j] - 1

        elementsInstance.elements[elementsType] = buffer

    nodes: nodes
    elements: elements
    vectors: vectors
    scalars: scalars

  reportProgress: ->
    @_completedLines++
    if @_completedLines % @_percentageChangeAt is 0
      postMessage
        type: 'progress'
        loadPercentage: 100.0 * @_completedLines / @_totalLines
