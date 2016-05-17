class TopViewer.SliderControl
  constructor: (@uiArea, @options) ->
    @options.minimumValue ?= 0
    @options.maximumValue ?= 100
    @options.value ?= 0
    @options.decimals ?= 0

    @$element = $("""
      <div class="slider-control #{@options.class}">
        <span class="value"><span class="number"></span></span>
        <div class="slider">
          <div class="track">
            <div class="thumb"></div>
          </div>
        </div>
      </div>
    """)

    @$value = @$element.find('.value')
    @$number = @$value.find('.number')
    @$slider = @$element.find('.slider')
    @$sliderThumb = @$slider.find('.thumb')

    if @options.unit
      @$value.append(" <class ='unit'>#{@options.unit}</div>")

    @options.$parent.append(@$element)

    # Create the top UI control for hovering purposes.
    new TopViewer.UIControl @uiArea, @$element

    sliderControl = new TopViewer.UIControl @uiArea, @$slider

    sliderControl.mousedown (position) =>
      @_sliderChanging = true
      @handleSlider position

    sliderControl.mousemove (position) =>
      @handleSlider position if @_sliderChanging

    sliderControl.globalMouseup =>
      @_sliderChanging = false

    @changeSlider @options.value

  handleSlider: (position) ->
    mouseXBrowser = @uiArea.$appWindow.offset().left + position.x
    sliderX = mouseXBrowser - (@$slider.offset().left + 5)
    rangePercentage = sliderX / (@$slider.width() - 10)

    unclampedValue = @options.minimumValue + (@options.maximumValue - @options.minimumValue) * rangePercentage
    @changeSlider unclampedValue

  changeSlider: (value) ->
    # Clamp the value to minimum/maximum.
    @value = Math.max @options.minimumValue, Math.min Math.round10(value, @options.decimals), Math.max @options.maximumValue

    @$slider.value = @value
    @$number.text @value

    thumbPercentage = 100.0 * (@value - @options.minimumValue) / (@options.maximumValue - @options.minimumValue)
    @$sliderThumb.css
      left: "#{thumbPercentage}%"

    @options.onChange?(@value)
