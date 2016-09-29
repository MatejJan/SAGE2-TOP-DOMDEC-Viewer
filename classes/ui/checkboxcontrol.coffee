class TopViewer.CheckboxControl
  constructor: (@uiArea, @options) ->
    @_value = @options.value

    # If we don't have a parent, undefined is assumed to be false.
    @_value ?= false unless @options.parent

    @$element = $("""
      <div class="checkbox-control #{@options.class}">
        <span class="value"></span> <span class="name">#{@options.name}</span>
      </div>
    """)

    @$value = @$element.find('.value')
    @_updateControl()

    @options.$parent.append(@$element)

    valueControl = new TopViewer.UIControl @uiArea, @$element
    
    valueControl.mousedown (position) =>
      if @options.parent
        # Cycle between true, false and inherit
        if @_value?
          @setValue if @_value then false else null

        else
          @setValue true

      else
        # Simply negate the value.
        @setValue not @_value

  setName: (name) ->
    @$element.find('.name').text(name)

  value: ->
    # If we have a value defined, simply return it.
    return @_value if @_value?

    # If we don't check if we have a parent checkbox and return its value.
    @options.parent?.value()

  setValue: (value) ->
    @_value = value
    @_updateControl()

    @options.onChange? @_value, @

  _updateControl: ->
    @$value.removeClass('true').removeClass('false').removeClass('inherit')

    if @_value?
      if @_value
        @$value.addClass('true')

      else
        @$value.addClass('false')

    else
      @$value.addClass('inherit')
