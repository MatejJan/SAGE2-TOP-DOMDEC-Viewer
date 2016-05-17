class TopViewer.CheckboxControl
  constructor: (@uiArea, @options) ->
    @value = @options.value

    @$element = $("""
      <div class="checkbox-control #{@options.class}">
        <span class="value"></span> <span class="name">#{@options.name}</span>
      </div>
    """)

    @$value = @$element.find('.value')

    @options.$parent.append(@$element)

    # Create the top UI control for hovering purposes.
    new TopViewer.UIControl @uiArea, @$element

    valueControl = new TopViewer.UIControl @uiArea, @$value

    valueControl.mousedown (position) =>
      @setValue not @value

  setValue: (value) ->
    @value = value

    if value
      @$value.addClass('true').removeClass('false')

    else
      @$value.addClass('false').removeClass('true')

    @options.onChange?(@value)
