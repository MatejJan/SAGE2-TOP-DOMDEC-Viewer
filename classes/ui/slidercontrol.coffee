class TopViewer.SliderControl
  constructor: (@uiArea, @options) ->
    @options.minimumValue ?= 0
    @options.maximumValue ?= 100
    @options.value ?= 0
    @options.decimals ?= 0
    @options.power ?= 1

    @$element = $("""
      <div class="slider-control #{@options.class}">
        <div class="slider">
          <div class="track">
            <div class="thumb"></div>
          </div>
        </div>
        <span class="value"><span class="number"></span></span>
      </div>
    """)

    @$value = @$element.find('.value')
    @$number = @$value.find('.number')
    @$slider = @$element.find('.slider')
    @$sliderThumb = @$slider.find('.thumb')

    if @options.unit
      @$value.append("#{if @options.unitWithoutSpace then "" else " "}<class ='unit'>#{@options.unit}</div>")

    @options.$parent.append(@$element)

    # Create the top UI control for hovering purposes.
    new TopViewer.UIControl @uiArea, @$element

    sliderControl = new TopViewer.UIControl @uiArea, @$slider

    sliderControl.mousedown (position) =>
      @_sliderChanging = true
      @handleSlider position

    sliderControl.globalMousemove (position) =>
      @handleSlider position if @_sliderChanging

    sliderControl.globalMouseup =>
      @_sliderChanging = false

    # Set the value, but skip onChange handler since we're in initialization.
    @setValue @options.value, true if @options.value?

  handleSlider: (position) ->
    mouseXBrowser = @uiArea.$appWindow.offset().left + position.x
    sliderX = mouseXBrowser - (@$slider.offset().left + 5)
    rangePercentage = sliderX / (@$slider.width() - 10)

    rangePercentage = Math.max 0, Math.min 1, rangePercentage

    # value = minimum + range * rangePercentage ^ power

    range = @options.maximumValue - @options.minimumValue
    unclampedValue = @options.minimumValue + range * Math.pow(rangePercentage, @options.power)
    @setValue unclampedValue

  setValue: (value, skipOnChange) ->
    # Clamp the value to minimum/maximum.
    @value = Math.max @options.minimumValue, Math.min Math.round10(value, @options.decimals), Math.max @options.maximumValue

    @$slider.value = @value
    @$number.text @value

    # thumbPercentage = ((value - minimum) / range) ^ 1/power

    range = @options.maximumValue - @options.minimumValue
    thumbPercentage = 100.0 * Math.pow((@value - @options.minimumValue) / range, 1 / @options.power)
    @$sliderThumb.css
      left: "#{thumbPercentage}%"

    @options.onChange? @value, @ unless skipOnChange
