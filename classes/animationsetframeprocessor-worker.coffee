'use strict'

importScripts '../libraries/three.min.js'

self.onmessage = (message) ->
  processStart = new Date()

  frame = message.data.frame
  console.log "Starting to process frame #{frame.time}."

  positions = frame.positions
  indices = frame.indices
  scalarFrame = frame.scalarFrame
  vectorFrame = frame.vectorFrame
  scalar =
    minValue: frame.scalarMinValue
    maxValue: frame.scalarMaxValue

  # Create colors.
  colors = new Float32Array positions.length

  totalElements = (scalarFrame?.scalars.length or 0) + (vectorFrame?.vectors.length or 0)
  completedElements = 0
  percentageChangeAt = Math.floor totalElements / 100

  reportProgress = ->
    completedElements++
    if completedElements % percentageChangeAt is 0
      postMessage
        type: 'progress'
        loadPercentage: 100.0 * completedElements / totalElements

  if scalarFrame
    console.log "Our scalar frame is #{scalarFrame.time}."

    for i in [0...scalarFrame.scalars.length]
      value = scalarFrame.scalars[i]
      normalizedValue = (value - scalar.minValue) / (scalar.maxValue - scalar.minValue)

      r = normalizedValue * 3
      g = (normalizedValue - 1/3) * 3
      b = (normalizedValue - 2/3) * 3
      colors[i * 3 + 0] = Math.min 1, Math.max 0, r
      colors[i * 3 + 1] = Math.min 1, Math.max 0, g
      colors[i * 3 + 2] = Math.min 1, Math.max 0, b

      reportProgress()

  else
    # If there's no scalar values, make the model white.
    for i in [0...colors.length]
      colors[i] = 1

  # Displace positions
  if vectorFrame
    for i in [0...vectorFrame.vectors.length]
      positions[i] += vectorFrame.vectors[i] * 10

      reportProgress()

  buffers =
    positions: positions
    indices: indices
    colors: colors

  processEnd = new Date()
  processTime = processEnd - processStart #ms
  console.log "Processed in #{processTime}ms"

  postMessage
    type: 'result'
    buffers: buffers

  close()
