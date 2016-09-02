class TopViewer.CheckboxControl
  constructor: (@uiArea, @options) ->
    @value = @options.value

    @$element = $("""
      <div class="checkbox-control #{@options.class}">
        <span class="value #{if @value then 'true' else ''}"></span> <span class="name">#{@options.name}</span>
      </div>
    """)

    @$value = @$element.find('.value')

    @options.$parent.append(@$element)

    valueControl = new TopViewer.UIControl @uiArea, @$element
    
    valueControl.mousedown (position) =>
      @setValue not @value

  setName: (name) ->
    @$element.find('.name').text(name)

  setValue: (value) ->
    @value = value

    if value
      @$value.addClass('true').removeClass('false')

    else
      @$value.addClass('false').removeClass('true')

    @options.onChange? @value, @
