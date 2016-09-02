class TopViewer.UIControl
  @_controls = []

  constructor: (@uiArea, @$element) ->
    @hover = false

    @_mouseDownHandlers = []
    @_mouseMoveHandlers = []
    @_mouseUpHandlers = []
    @_mouseScrollHandlers = []
    @_globalMouseMoveHandlers = []
    @_globalMouseUpHandlers = []

    @uiArea.addControl @

    @$element.data("control", @)

  mousedown: (handler) ->
    @_mouseDownHandlers.push handler

  mousemove: (handler) ->
    @_mouseMoveHandlers.push handler

  mouseup: (handler) ->
    @_mouseUpHandlers.push handler

  scroll: (handler) ->
    @_mouseScrollHandlers.push handler

  globalMousemove: (handler) ->
    @_globalMouseMoveHandlers.push handler

  globalMouseup: (handler) ->
    @_globalMouseUpHandlers.push handler

  click: (handler) ->
    @mouseup handler

  onMouseDown: (position, button) ->
    handler position, button for handler in @_mouseDownHandlers

  onMouseMove: (position) ->   
    handler position for handler in @_mouseMoveHandlers

  onMouseUp: (position, button) ->
    handler position, button for handler in @_mouseUpHandlers

  onGlobalMouseMove: (position, button) ->
    handler position, button for handler in @_globalMouseMoveHandlers

  onGlobalMouseUp: (position, button) ->
    handler position, button for handler in @_globalMouseUpHandlers

  onMouseScroll: (delta) ->
    handler delta for handler in @_mouseScrollHandlers
