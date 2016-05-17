class TopViewer.UIControl
  @_controls = []

  constructor: (@uiArea, @$element) ->
    @hover = false

    @_mouseDownHandlers = []
    @_mouseMoveHandlers = []
    @_mouseUpHandlers = []
    @_globalMouseUpHandlers = []

    @uiArea.addControl @

  mousedown: (handler) ->
    @_mouseDownHandlers.push handler

  mousemove: (handler) ->
    @_mouseMoveHandlers.push handler

  mouseup: (handler) ->
    @_mouseUpHandlers.push handler

  globalMouseup: (handler) ->
    @_globalMouseUpHandlers.push handler

  click: (handler) ->
    @mouseup handler

  onMouseDown: (position, button) ->
    return unless @hover and @$element.is(':visible')

    handler position, button for handler in @_mouseDownHandlers

  onMouseMove: (position) ->
    parentOrigin = @uiArea.$appWindow.offset()
    origin = @$element.offset()
    left = origin.left - parentOrigin.left
    top = origin.top - parentOrigin.top
    right = left + @$element.outerWidth()
    bottom = top + @$element.outerHeight()
    newHover = left < position.x < right and top < position.y < bottom

    @$element.addClass('hover') if newHover and not @hover
    @$element.removeClass('hover') if @hover and not newHover

    @hover = newHover

    handler position for handler in @_mouseMoveHandlers

  onMouseUp: (position, button) ->
    handler position, button for handler in @_globalMouseUpHandlers

    return unless @hover and @$element.is(':visible')

    handler position, button for handler in @_mouseUpHandlers
