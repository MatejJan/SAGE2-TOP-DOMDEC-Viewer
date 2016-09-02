'use strict'

class TopViewer.UIArea
  constructor: (@$appWindow) ->
    # Keep a list of controls on which to call events.
    @_controls = []
    @_hoveredStack = []

    @$rootElement = null

  destroy: ->
    @$appWindow = null
    control.destroy?() for control in @_controls
    @_controls = null

  addControl: (control) ->
    @_controls.push control

  onMouseDown: (position, button) ->
    control.onMouseDown position, button for control in @_hoveredStack

  onMouseMove: (position) ->
    # Clean previously hovered elements.
    for control in @_hoveredStack
      control.hover = false
      control.$element.removeClass('hover')

    @_hoveredStack = []

    # Determine which element we're hovering on.
    parentOrigin = @$appWindow.offset()
    $pointers = $('.pointerItem')
    $pointers.hide()
    element = document.elementFromPoint parentOrigin.left + position.x,  parentOrigin.top + position.y
    $pointers.show()

    # Are we even inside this area?
    return unless @$rootElement.has(element).length or @$rootElement.is(element)

    # Travel up the parents of the element until a control is found.
    $element = $(element)
    control = $element.data('control')
    @_hoveredStack.push control if control

    while $element.parent().length
      $element = $element.parent()
      control = $element.data('control')
      @_hoveredStack.push control if control

    # Set newly hovered elements.
    for control in @_hoveredStack
      control.hover = true
      control.$element.addClass('hover')

    control.onMouseMove position for control in @_hoveredStack
    control.onGlobalMouseMove position for control in @_controls

  onMouseUp: (position, button) ->
    control.onMouseUp position, button for control in @_hoveredStack
    control.onGlobalMouseUp position, button for control in @_controls

  onMouseScroll: (delta) ->
    control.onMouseScroll delta for control in @_hoveredStack
