'use strict'

importScripts '../libraries/three.min.js'
importScripts '../libraries/underscore-min.js'

self.onmessage = (message) ->
  url = message.data.url

  # This function loads the top/xpost file from the provided url. Because this can be huge files, we load them
  # incrementally, parsing the text as we go and reporting frames back to the main thread as soon as they are complete.
  # To do this we request chunks of file data from the server and send each line of text to the parser.
  parser = new TopParser url

  # We load 100 MB chunks at a time.
  rangeLength = 100 * 1024 * 1024

  requestRangeStart = 0
  requestRangeEnd = rangeLength - 1

  # Determine the total file size by creating a dummy (1 byte) synchronous request to the server.
  request = new XMLHttpRequest
  request.open 'GET', url, false
  request.setRequestHeader 'Range', "bytes=0-0"
  request.send null
  rangeHeader = request.getResponseHeader 'Content-Range'
  rangeHeaderParts = rangeHeader.match /bytes (\d+)-(\d+)\/(\d+)/
  totalLength = parseInt rangeHeaderParts[3]

  postMessage
    type: 'size'
    size: totalLength

  #console.log "Loading #{totalLength} bytes."

  loadChunk = =>
    # Clamp range end to total length so we don't read beyond the end of the file.
    requestRangeEnd = Math.min requestRangeEnd, totalLength - 1
    #console.log "Loading chunk: #{requestRangeStart}-#{requestRangeEnd}."

    # Open a new request synchronously, since we're already in a worker and don't need async functionality.
    request = new XMLHttpRequest
    request.open 'GET', url

    # Request one chunk of binary data.
    request.setRequestHeader 'Range', "bytes=#{requestRangeStart}-#{requestRangeEnd}"
    request.responseType = 'blob'
    request.onload = (event) =>
      # Parse the response header.
      rangeHeader = request.getResponseHeader 'Content-Range'
      rangeHeaderParts = rangeHeader.match /bytes (\d+)-(\d+)\/(\d+)/
      rangeStart = parseInt rangeHeaderParts[1]
      rangeEnd = parseInt rangeHeaderParts[2]
      totalLength = parseInt rangeHeaderParts[3]

      # Make sure that the returned range matches what we requested.
      console.error "Returned range start does not match our request." unless requestRangeStart is rangeStart
      console.error "Returned range end does not match our request." unless requestRangeEnd is rangeEnd

      # Read response data as text and send it to the parser.
      reader = new FileReader
      reader.onload = (event) =>
        parser.parse reader.result, rangeStart / totalLength, (rangeEnd - rangeStart) / totalLength

        # Complete parsing when we've parsed the last chunk.
        if rangeEnd is totalLength - 1
          parser.end()

      reader.readAsText request.response

      # See if we have reached the end of the file.
      if rangeEnd < totalLength - 1
        # Increment the range to the next chunk.
        requestRangeStart += rangeLength
        requestRangeEnd += rangeLength

        # Start loading the next chunk.
        loadChunk()

      else
        # console.log "Loading finished."

    # Initiate the request to load the chunk range.
    request.send()

  # Start loading chunks.
  loadChunk()

class TopParser
  @modes:
    Nodes: 'Nodes'
    Elements: 'Elements'
    VectorCount: 'VectorCount'
    VectorTime: 'VectorTime'
    Vector: 'Vector'
    ScalarCount: 'ScalarCount'
    ScalarTime: 'ScalarTime'
    Scalar: 'Scalar'

  constructor: (@url) ->
    @lastLine = null

    @currentMode = null

    @currentNodesName = null
    @currentNodes = null

    @currentElementsName = null
    @currentElements = null

    @currentVectorNodesName = null
    @currentVectorName = null
    @currentVector = null

    @currentScalarNodesName = null
    @currentScalarName = null
    @currentScalar = null

    @currentFrame = null
    @currentFrameTime = null
    @currentFrameNodesCount = null
    @currentFrameNodeIndex = null

    @reportedProgressPercentage = 0

    @throttledEndScalar = _.throttle =>
      @endScalar()
    , 3000, leading: false

    @throttledEndVector = _.throttle =>
      @endVector()
    , 3000, leading: false

  parse: (data, progressPercentageStart, progressPercentageLength) ->
    # First see if the new data starts with a new line. This would mean that previous last line should be considered
    # complete and should be processed straight away (instead of adding it to the first line of this parse).
    if data[0] is '\n'
      @parseLine @lastLine
      @lastLine = null

    lines = data.match /[^\r\n]+/g

    # The last line in the new parse is complete if the data ended with a new line.
    lastLineIsComplete = false
    if data[data.length-1] is '\n'
      lastLineIsComplete = true

    # Only parse all but the last line (it's probably incomplete).
    parseLineCount = if lastLineIsComplete then lines.length else lines.length - 1

    # Add the incomplete last line from previous parse to the first line of this parse to generate a complete line.
    lines[0] = "#{@lastLine}#{lines[0]}" if @lastLine

    # Parse all the lines.
    if parseLineCount > 0
      for lineIndex in [0...parseLineCount]
        @parseLine lines[lineIndex]

        @reportProgress progressPercentageStart + progressPercentageLength * lineIndex / (parseLineCount - 1)

    # Store the last line for the future.
    @lastLine = if lastLineIsComplete then null else lines[lines.length-1]

  parseLine: (line) ->
    # Split by whitespace.
    parts = line.match /\S+/g

    # Detect modes.
    switch parts[0]
      when 'Nodes'
        @endCurrentMode()
        @currentMode = @constructor.modes.Nodes

        # Parse nodes header.
        @currentNodesName = parts[1]
        @currentNodes =
          nodes: []

        return

      when 'Elements'
        @endCurrentMode()
        @currentMode = @constructor.modes.Elements

        # Parse elements header.
        @currentElementsName = parts[1]
        @currentElements =
          elements: {}
          nodesName: parts[3]

        return

      when 'Vector'
        @endCurrentMode()
        @currentMode = @constructor.modes.VectorCount

        # Parse vector header.
        @currentVectorNodesName = parts[5]
        @currentVectorName = parts[1]
        @currentVector =
          vectorName: parts[1]
          nodesName: parts[5]
          frames: []

        return

      when 'Scalar'
        @endCurrentMode()
        @currentMode = @constructor.modes.ScalarCount

        # Parse scalars header.
        @currentScalarNodesName = parts[5]
        @currentScalarName = parts[1]
        @currentScalar =
          scalarName: parts[1]
          nodesName: parts[5]
          frames: []

        return

    # No mode switch was detected, continue business as usual.
    switch @currentMode
      when @constructor.modes.Nodes
        # Parse node.
        vertexIndex = parseInt parts[0]
        vertex =
          x: parseFloat parts[1]
          y: parseFloat parts[2]
          z: parseFloat parts[3]

        @currentNodes.nodes[vertexIndex] = vertex

      when @constructor.modes.Elements
        # Parse element.
        elementIndex = parseInt parts[0]
        elementType = parseInt parts[1]
        @currentElements.elements[elementType] ?= []

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
            console.error "UNKNOWN ELEMENT TYPE", elementType, parts, line, @lastLine

        @currentElements.elements[elementType].push newElement

      when @constructor.modes.VectorCount
        # Read number of nodes.
        @currentFrameNodesCount = parseInt parts[0]
        @currentMode = @constructor.modes.VectorTime

      when @constructor.modes.VectorTime
        # Read frame time.
        @currentFrameTime = parseFloat parts[0]
        @currentMode = @constructor.modes.Vector

        @currentFrame =
          time: @currentFrameTime
          vectors: new Float32Array @currentFrameNodesCount * 3

        @currentFrameNodeIndex = 0

      when @constructor.modes.Vector
        @currentFrame.vectors[@currentFrameNodeIndex * 3] = parseFloat parts[0]
        @currentFrame.vectors[@currentFrameNodeIndex * 3 + 1] = parseFloat parts[1]
        @currentFrame.vectors[@currentFrameNodeIndex * 3 + 2] = parseFloat parts[2]
        @currentFrameNodeIndex++

        if @currentFrameNodeIndex is @currentFrameNodesCount
          # Add completed vector frame to frames.
          @currentVector.frames.push @currentFrame

          @endVectorFrame()
          @currentMode = @constructor.modes.VectorTime

      when @constructor.modes.ScalarCount
        # Read number of nodes.
        @currentFrameNodesCount = parseInt parts[0]
        @currentMode = @constructor.modes.ScalarTime

      when @constructor.modes.ScalarTime
        # Read frame time.
        @currentFrameTime = parseFloat parts[0]
        @currentMode = @constructor.modes.Scalar

        @currentFrame =
          time: @currentFrameTime
          scalars: new Float32Array @currentFrameNodesCount
          minValue: null
          maxValue: null

        @currentFrameNodeIndex = 0

      when @constructor.modes.Scalar
        value = parseFloat parts[0]
        @currentFrame.minValue = value unless @currentFrame.minValue? and @currentFrame.minValue < value
        @currentFrame.maxValue = value unless @currentFrame.maxValue? and @currentFrame.maxValue > value

        @currentFrame.scalars[@currentFrameNodeIndex] = value
        @currentFrameNodeIndex++

        if @currentFrameNodeIndex is @currentFrameNodesCount
          # Add completed scalar frame to frames.
          @currentScalar.frames.push @currentFrame

          @endScalarFrame()
          @currentMode = @constructor.modes.ScalarTime

  endCurrentMode: ->
    switch @currentMode
      when @constructor.modes.Nodes
        @endNodes()

      when @constructor.modes.Elements
        @endElements()

      when @constructor.modes.Vector
        @endVector()

      when @constructor.modes.Scalar
        @endScalar()

  endNodes: ->
    # Create nodes array buffer.
    length = Math.max 0, @currentNodes.nodes.length - 1
    buffer = new Float32Array length * 3

    for i in [0...length]
      # Convert to 0-based indices and skip over non-existent nodes
      # (they simply won't be used, although they take space).
      if @currentNodes.nodes[i+1]
        buffer[i*3] = @currentNodes.nodes[i+1].x
        buffer[i*3+1] = @currentNodes.nodes[i+1].y
        buffer[i*3+2] = @currentNodes.nodes[i+1].z

    @currentNodes.nodes = buffer

    nodesResult = {}
    nodesResult[@currentNodesName] = @currentNodes

    postMessage
      type: 'result'
      objects:
        nodes: nodesResult

  endElements: ->
    # Create elements array buffer.
    nodesPerElement =
      "4": 3
      "5": 4

    for elementsType, elementsList of @currentElements.elements
      elementSize = nodesPerElement[elementsType]
      buffer = new Uint32Array elementsList.length * elementSize
      for i in [0...elementsList.length]
        for j in [0...elementSize]
          # Convert to 0-based indices.
          buffer[i*elementSize+j] = elementsList[i][j] - 1

      @currentElements.elements[elementsType] = buffer

    elementsResult = {}
    elementsResult[@currentElementsName] = @currentElements

    postMessage
      type: 'result'
      objects:
        elements: elementsResult

  endScalar: ->
    return unless @currentScalar.frames.length

    scalarsResult = {}
    scalarsResult[@currentScalarNodesName] = {}
    scalarsResult[@currentScalarNodesName][@currentScalarName] = @currentScalar

    postMessage
      type: 'result'
      objects:
        scalars: scalarsResult

    @currentScalar.frames = []

  endVector: ->
    return unless @currentVector.frames.length

    vectorsResult = {}
    vectorsResult[@currentVectorNodesName] = {}
    vectorsResult[@currentVectorNodesName][@currentVectorName] = @currentVector

    postMessage
      type: 'result'
      objects:
        vectors: vectorsResult

    @currentVector.frames = []

  endScalarFrame: ->
    @throttledEndScalar()

  endVectorFrame: ->
    @throttledEndVector()

  end: ->
    @endCurrentMode()

    postMessage
      type: 'complete'

  reportProgress: (percentage) ->
    newPercentage = Math.floor(percentage * 100)

    if newPercentage > @reportedProgressPercentage
      @reportedProgressPercentage = newPercentage

      postMessage
        type: 'progress'
        loadPercentage: newPercentage
