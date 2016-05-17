'use strict'

importScripts '../libraries/three.min.js'

self.onmessage = (message) ->
  url = message.data.url
  loader = new THREE.XHRLoader @manager
  loader.setResponseType 'arraybuffer'

  #console.log "Loading hive file.", url

  loadStart = new Date()

  loader.load url, (data) =>
    loadEnd = new Date()
    loadTime = loadEnd - loadStart #ms
    console.log "Loaded in #{loadTime}ms", url

    worker = new HiveWorker()
    postMessage
      type: 'result'
      objects: worker.parse data, url

    #console.log "Closing worker.", url
    close()

class HiveWorker
  parse: (data, url) ->
    #console.log "Parsing hive file with length #{data.byteLength} bytes.", url

    headerData = new Uint32Array data, 0, 12 # bytes

    # Parse header.
    flags = headerData[0]
    vertexCount = headerData[1]
    faceCount = headerData[2]

    #console.log "Header: Flags=#{(flags >>> 0).toString(2)} #vertices=#{vertexCount} #faces=#{faceCount}"

    isIndexed = flags & 256
    hasNormals = flags & 8

    #console.log "Faces are indexed." if isIndexed
    #console.log "Model has normals." if hasNormals

    # Vertex has 3 floats for positions and 4 bytes for colors, total of 4 32-bit numbers.
    vertexDataSize = 4

    # Vertex has additional 3 floats for normals.
    vertexDataSize += 3 if hasNormals

    #console.log "Vertex has #{vertexDataSize * 4} bytes."

    # Offsets tell us how many 32-bit elements the attribute starts at.
    vertexPositionOffset = 0
    vertexColorOffset = if hasNormals then 6 else 3
    vertexNormalOffset = 3

    # Color offsets need to be scaled by 4 since they are 8-bit values.
    vertexColorFactor = 4

    # Read vertex data.
    positionData = new Float32Array data, 12, vertexCount * vertexDataSize
    colorData = new Uint8Array data, 12, vertexCount * vertexDataSize * vertexColorFactor

    #console.log colorData

    positions = new Float32Array vertexCount * 3
    colors = new Float32Array vertexCount * 3

    @_totalElements = vertexCount * 2
    @_totalElements += vertexCount if hasNormals

    @_percentageChangeAt = Math.floor @_totalElements / 100
    @_completedElements = 0

    for i in [0...vertexCount]
      for j in [0...3]
        positions[i * 3 + j] = positionData[i * vertexDataSize + vertexPositionOffset + j]

      @reportProgress()

      for j in [0..2]
        color = colorData[(i * vertexDataSize + vertexColorOffset) * vertexColorFactor + j]
        colors[i * 3 + j] = color / 256.0

      @reportProgress()

    # We don't care about included normals as we'll recompute them.
    ###
    if hasNormals
      normalData = new Float32Array data, 12, vertexCount * vertexDataSize
      normals = new Float32Array vertexCount * 3

      for i in [0...vertexCount]
        for j in [0..2]
          normals[i * 3 + j] = normalData[i * vertexDataSize + vertexNormalOffset + j]

        @reportProgress()

      buffers.normals = normals
    ###

    indices = new Uint32Array data, 12 + vertexCount * vertexDataSize * 4, faceCount * 3 if isIndexed

    # Name objects based on the filename
    filenameStartIndex = url.lastIndexOf('/') + 1
    filename = url.substring filenameStartIndex

    # Create nodes from positions.
    nodesName = "#{filename}.nodes"
    nodes = {}
    nodes[nodesName] =
      nodes: positions

    # Create elements from indices.
    elementsName = "#{filename}.elements"
    elements = {}
    if indices
      elements[elementsName] =
        elements: indices
        nodesName: nodesName

    # Determine time from filename
    frameIndexRegex = /(\d+)(?!.*\d)/

    matches = filename.match frameIndexRegex
    time = if matches[0] then parseFloat matches[0] else -1

    # Create scalars from colors.
    frame =
      time: time
      scalars: new Float32Array vertexCount
      minValue: null
      maxValue: null

    color = new THREE.Color
    for i in [0...vertexCount]
      color.setRGB colors[i*3], colors[i*3+1], colors[i*3+2]
      value = -color.getHSL().h
      frame.scalars[i] = value
      frame.minValue = value unless frame.minValue? and frame.minValue < value
      frame.maxValue = value unless frame.maxValue? and frame.maxValue > value

    scalarName = "#{filename}.scalar"
    scalars = {}
    scalars[nodesName] = {}
    scalars[nodesName][scalarName] =
      scalarName: scalarName
      nodesName: nodesName
      frames: [frame]

    nodes: nodes
    elements: elements
    vectors: {}
    scalars: scalars

  reportProgress: ->
    @_completedElements++
    if @_completedElements % @_percentageChangeAt is 0
      postMessage
        type: 'progress'
        loadPercentage: 100.0 * @_completedElements / @_totalElements
