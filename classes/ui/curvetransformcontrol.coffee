binsCount = 100
histogramHeight = 25

class TopViewer.CurveTransformControl
  @_controls = []

  constructor: (@uiArea, @options) ->
    @constructor._controls.push @

    @$element = $("""
      <div class="curve-transform-control #{@options.class}">
        <canvas class='histogram-canvas'></canvas>
        <div class='isovalues-slider-area'></div>
        <div class='curve-area'>
          <canvas class='curve-canvas' height='256' width='256'></canvas>
          <canvas class='spectrogram-canvas'></canvas>
        </div>
        <canvas class='isovalues-canvas'></canvas>
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

    @isovaluesCanvas = @$element.find('.isovalues-canvas')[0]
    @isovaluesCanvas.width = 120
    @isovaluesCanvas.height = 200
    @isovaluesContext = @isovaluesCanvas.getContext '2d'

    @colorCurve = new ColorCurve @$element.find('.curve-canvas')[0]

    @clip =
      min: @options.scalar.limits.minValue
      max: @options.scalar.limits.maxValue

    @currentClipProperty = null

    @isovaluesControl = new TopViewer.SliderControl @uiArea,
      $parent: @$element.find('.isovalues-slider-area')
      minimumValue: 1
      maximumValue: 9
      value: @options.saveState.isovalues
      decimals: 0
      onChange: (value) =>
        @options.saveState.isovalues = value
        @drawSpectrogram()

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

      @drawSpectrogram()

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
      frame.maxBinValue = 0

      # Get maximum of 1000 samples.
      sampleStep = Math.floor Math.max 1, frame.scalars.length / 1000

      for scalarValue in frame.scalars by sampleStep
        binIndex = Math.floor (scalarValue - min) / binWidth
        continue unless 0 <= binIndex < binsCount
        frame.bins[binIndex]++
        @maxBinValue = frame.bins[binIndex] if frame.bins[binIndex] > @maxBinValue
        frame.maxBinValue = frame.bins[binIndex] if frame.bins[binIndex] > frame.maxBinValue

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
    # Get gradient color data.
    gradient = @options.gradientControl.value

    # Render spectrogram.
    imageData = @spectrogramContext.createImageData @spectrogramCanvas.width, @spectrogramCanvas.height
    for frame, frameIndex in @options.scalar.frames
      for binValue, binIndex in frame.bins
        pixelIndex = (frameIndex * binsCount + binIndex) * 4

        value = Math.min 255, binValue / frame.maxBinValue * 1000
        color = gradient.colorAtPercentage @colorCurve.getY binIndex / binsCount

        imageData.data[pixelIndex] = color.r
        imageData.data[pixelIndex+1] = color.g
        imageData.data[pixelIndex+2] = color.b
        imageData.data[pixelIndex+3] = value

    @spectrogramContext.putImageData imageData, 0, 0

    # Now write and draw the isovalues.

    @isovaluesContext.fillStyle = 'black'
    @isovaluesContext.clearRect 0, 0, @isovaluesCanvas.width, @isovaluesCanvas.height
    range = @clip.max - @clip.min

    isovalues = @isovaluesControl.value

    @isovaluesContext.font = "#{35-isovalues}px 'Ubuntu Condensed'"
    @isovaluesContext.textAlign = 'center'
    @isovaluesContext.textBaseline = 'middle'
    @isovaluesContext.strokeStyle = 'black'
    @isovaluesContext.lineWidth = 8

    @spectrogramContext.lineWidth = 1
    @spectrogramContext.strokeStyle = 'rgba(255,255,255,0.5)'

    @spectrogramContext.beginPath()

    drawIsovalue = (value) =>
      percentageValue = (value - @clip.min) / range
      curvedValue = @colorCurve.getX percentageValue

      color = gradient.colorAtPercentage percentageValue
      @isovaluesContext.fillStyle = "rgb(#{color.r}, #{color.g}, #{color.b})"

      value = @clip.min + curvedValue * range
      text = @_convertToScientificNotation value

      middle = @isovaluesCanvas.width / 2
      y = (1 - curvedValue) * (@isovaluesCanvas.height - 10) + 5

      @isovaluesContext.strokeText text, middle, y #if color.r + color.g + color.b < 256
      @isovaluesContext.fillText text, middle, y

      # Now draw the line on the spectrogram.
      x = curvedValue * @spectrogramCanvas.width
      @spectrogramContext.moveTo x, 0
      @spectrogramContext.lineTo x, @spectrogramCanvas.height

    isovalueStep = 1.0 / (isovalues + 1)

    for isosurfaceIndex in [0...isovalues]
      percentageIsovalue = isovalueStep * (isosurfaceIndex + 1)
      isovalue = @clip.min + percentageIsovalue * range
      drawIsovalue isovalue

    @spectrogramContext.stroke()

  _convertToScientificNotation: (value) ->
    exponent = 0

    if Math.abs(value) > 1
      while Math.abs(value) > 100
        value /= 1000
        exponent += 3

    else
      while Math.abs(value) < 0.01
        value *= 1000
        exponent -= 3

    "#{Math.round10 value, -3}#{if exponent then "e#{exponent}" else ''}"

  _convertToPrefixNotation: (value) ->
    prefixesLarger = ['', 'k', 'M', 'G', 'T', 'P', 'E']
    prefixesSmaller = ['', 'm', 'μ', 'n', 'p', 'f', 'a']

    largerIndex = 0
    smallerIndex = 0

    if Math.abs(value) > 1
      while Math.abs(value) > 100
        value /= 1000
        largerIndex += 1

    else
      while Math.abs(value) < 0.01
        value *= 1000
        smallerIndex += 1

    "#{Math.round10 value, -3}#{prefixesLarger[largerIndex]}#{prefixesSmaller[smallerIndex]}"

  @update: -> control.update() for control in @_controls
  @drawSpectrogram: -> control.drawSpectrogram() for control in @_controls

  @mouseDown: (position) -> control.colorCurve.mouseDown position for control in @_controls
  @mouseMove: (position) -> control.colorCurve.mouseMove position for control in @_controls
  @mouseUp: (position) -> control.colorCurve.mouseUp position for control in @_controls
