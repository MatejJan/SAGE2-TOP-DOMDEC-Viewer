binsCount = 100
histogramHeight = 25

class TopViewer.CurveTransformControl
  @_controls = []

  constructor: (@uiArea, @options) ->
    @constructor._controls.push @

    @$element = $("""
      <div class="curve-transform-control #{@options.class}">
        <canvas class='histogram-canvas' height='25' width='100'></canvas>
        <div class='curve-area'>
          <canvas class='curve-canvas' height='256' width='256'></canvas>
          <canvas class='spectrogram-canvas' height='100' width='100'></canvas>
        </div>
      </div>
    """)

    @$histogramCanvas = @$element.find('.histogram-canvas')
    @histogramCanvas = @$histogramCanvas[0]
    @histogramCanvas.width = binsCount
    @histogramCanvas.height = histogramHeight
    @histogramContext = @histogramCanvas.getContext '2d'

    @spectrogramCanvas = @$element.find('.spectrogram-canvas')[0]
    @spectrogramCanvas.width = binsCount
    @spectrogramCanvas.height = @options.scalar.frames.length
    @spectrogramContext = @spectrogramCanvas.getContext '2d'

    @colorCurve = new ColorCurve @$element.find('.curve-canvas')[0]

    @clip =
      min: @options.scalar.limits.minValue
      max: @options.scalar.limits.maxValue

    @currentClipProperty = null

    if @options.saveState
      # Convert object properties to array.
      points = []
      points.push @options.saveState.points[i] for i in [0..3]

      @colorCurve.setPoints points

      @clip.min = @options.saveState.clip.min if @options.saveState.clip.min
      @clip.max = @options.saveState.clip.max if @options.saveState.clip.max

    @options.$parent.append(@$element)

    @curveData = new Float32Array 4096
    @curveTexture = new THREE.DataTexture @curveData, 4096, 1, THREE.AlphaFormat, THREE.FloatType, THREE.UVMapping, THREE.ClampToEdgeWrapping, THREE.ClampToEdgeWrapping, THREE.LinearFilter, THREE.LinearFilter

    clipControl = new TopViewer.UIControl @uiArea, @$element.find('.histogram-canvas')

    clipControl.mousedown (position) =>
      @_clipControlChanging = true
      @handleClipDragging position

    clipControl.globalMousemove (position) =>
      @handleClipDragging position if @_clipControlChanging

    clipControl.globalMouseup =>
      @_clipControlChanging = false
      @currentClipProperty = null

    @updateHistogram()

  handleClipDragging: (position) ->
    x = @uiArea.$appWindow.offset().left + position.x - @$histogramCanvas.offset().left

    min = @options.scalar.limits.minValue
    max = @options.scalar.limits.maxValue
    range = max - min

    value = min + range * x / @$histogramCanvas.width()
    value = Math.max min, Math.min max, value

    unless @currentClipProperty
      distanceToMin = Math.abs value - @clip.min
      distanceToMax = Math.abs value - @clip.max

      if distanceToMin < distanceToMax
        @currentClipProperty = 'min'

      else
        @currentClipProperty = 'max'

    # Make sure the value can't go to the other side of the opposite clipping point.
    if @currentClipProperty is 'min'
      value = Math.min value, @clip.max

    else
      value = Math.max value, @clip.min

    @clip[@currentClipProperty] = value
    @options.saveState.clip = @clip

    @drawHistogram()
    @updateSpectrogram()

  update: ->
    # Update gradient curve data.
    unless @_lastUpdated is @colorCurve.lastUpdated
      @_lastUpdated = @colorCurve.lastUpdated
      @curveData[i] = @colorCurve.getY(i/4096) for i in [0...4096]
      @curveTexture.needsUpdate = true

      if @options.saveState
        @options.saveState.points[i] = @colorCurve.points[i] for i in [0..3]

  updateHistogram: ->
    min = @options.scalar.limits.minValue
    max = @options.scalar.limits.maxValue
    range = max - min
    binWidth = range / binsCount

    @histogramBins = []
    @histogramBins[i] = 0 for i in [0..binsCount]
    @maxHistogramBinValue = 0

    # Accumulate bin values.
    for frame, frameIndex in @options.scalar.frames
      # Get maximum of 1000 samples.
      sampleStep = Math.floor Math.max 1, frame.scalars.length / 1000

      for scalarValue in frame.scalars by sampleStep
        binIndex = Math.floor (scalarValue - min) / binWidth
        continue unless 0 <= binIndex < binsCount
        @histogramBins[binIndex]++
        @maxHistogramBinValue = @histogramBins[binIndex] if @histogramBins[binIndex] > @maxHistogramBinValue

    @drawHistogram()

    @updateSpectrogram()

  updateSpectrogram: ->
    min = Math.max @clip.min, @options.scalar.limits.minValue
    max = Math.min @clip.max, @options.scalar.limits.maxValue
    range = max - min
    binWidth = range / binsCount

    @maxBinValue = 0

    # Accumulate bin values.
    for frame, frameIndex in @options.scalar.frames
      frame.bins = []
      frame.bins[i] = 0 for i in [0..binsCount]

      # Get maximum of 1000 samples.
      sampleStep = Math.floor Math.max 1, frame.scalars.length / 1000

      for scalarValue in frame.scalars by sampleStep
        binIndex = Math.floor (scalarValue - min) / binWidth
        continue unless 0 <= binIndex < binsCount
        frame.bins[binIndex]++
        @maxBinValue = frame.bins[binIndex] if frame.bins[binIndex] > @maxBinValue

    @drawSpectrogram()

  drawHistogram: ->
    @histogramContext.clearRect 0, 0, @histogramCanvas.width, @histogramCanvas.height
    min = @options.scalar.limits.minValue
    max = @options.scalar.limits.maxValue
    range = max - min

    # Render histogram.
    @histogramContext.beginPath()

    for i in [0..binsCount]
      @histogramContext.moveTo i, histogramHeight
      @histogramContext.lineTo i, histogramHeight * (1 - @histogramBins[i] / @maxHistogramBinValue)

    @histogramContext.strokeStyle = 'rgba(255,255,255,0.5)'
    @histogramContext.stroke()

    # Draw clipping points.
    @histogramContext.beginPath()

    for value in [@clip.min, @clip.max]
      x = (value - min) / range * binsCount
      @histogramContext.moveTo x, 0
      @histogramContext.lineTo x, histogramHeight

    @histogramContext.strokeStyle = 'rgba(255,255,255,1)'
    @histogramContext.stroke()

  drawSpectrogram: ->
    # Render spectrogram.
    imageData = @spectrogramContext.createImageData @spectrogramCanvas.width, @spectrogramCanvas.height
    for frame, frameIndex in @options.scalar.frames
      for binValue, binIndex in frame.bins
        pixelIndex = (frameIndex * binsCount + binIndex) * 4
        colorValue = binValue / @maxBinValue * 255
        imageData.data[pixelIndex] = 255
        imageData.data[pixelIndex+1] = 255
        imageData.data[pixelIndex+2] = 255
        imageData.data[pixelIndex+3] = colorValue

    @spectrogramContext.putImageData imageData, 0, 0

  @update: -> control.update() for control in @_controls
  @mouseDown: (position) -> control.colorCurve.mouseDown position for control in @_controls
  @mouseMove: (position) -> control.colorCurve.mouseMove position for control in @_controls
  @mouseUp: (position) -> control.colorCurve.mouseUp position for control in @_controls
