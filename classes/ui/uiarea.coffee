'use strict'

class TopViewer.UIArea
  constructor: (@$appWindow) ->
    # Keep a list of controls on which to call events.
    @_controls = []
    @_hoveredStack = []

    @$rootElement = null

    @_throttledMouseMoveHandler = _.throttle @_mouseMoveHandler, 100
    @_throttledInitialize = _.throttle @initialize, 100, leading: false

  destroy: ->
    # Set destroying to true to prevent controls being removed while we're iterating over them.
    @_destroying = true

    control.destroy?() for control in @_controls

    @_controls = []

  addControl: (control) ->
    @_controls.push control

    # We need to reinitialize any time new controls are added after the first initialization.
    @_throttledInitialize() if @_initialized

  removeControl: (control) ->
    return if @_destroying

    index = _.indexOf @_controls, control
    @_controls.splice index, 1

    # We need to reinitialize any time new controls are added after the first initialization.
    @_throttledInitialize() if @_initialized

  # This must be called at the end of the constructor in the inherited UI area.
  initialize: ->
    @_initialized = true

    # We need to allow the DOM to be rendered.
    setTimeout =>
      # Create the ordered list of all controls in their rendering order. We will use
      # this on mouse move to determine which control the mouse is hovering over.

      # We start by creating an ordered list of all the elements, which we'll later filter to just the controls.
      sortedElements = []

      addElements = ($element, elements) =>
        zIndexString = $element.css('z-index')
        zIndex = if zIndexString is 'auto' then 0 else parseInt zIndexString

        newElements = null

        # Let's see if we create a stacking context.
        if zIndexString isnt 'auto'
          # Start a new array of elements.
          newElements = []

        # Add all the children, either to same context or the new one.
        children = $element.children().toArray()

        if children.length
          addElements $(child), newElements or elements for child in children

        # Create this elements entry.
        element =
          $element: $element
          zIndex: zIndex

        element.children = newElements if newElements?.length

        # Add the element.
        elements.push element

      # Recursively add all elements in the UI area.
      addElements @$rootElement, sortedElements

      # Sort all of the stacking contexts.
      sortContext = (elements) =>
        elements.sort (a, b) =>
          b.zIndex - a.zIndex

        # Also stack all sub-contexts.
        sortContext element.element for element in elements when _.isArray element.element

      # Now filter this down to controls.
      @_sortedControls = []

      addControls = (elements) =>
        for element in elements
          if _.isArray element.children
            addControls element.children

          control = element.$element.data('control')
          @_sortedControls.push control if control

      addControls sortedElements
    ,
      0

  onMouseDown: (position, button) ->
    control.onMouseDown position, button for control in @_hoveredStack

  onMouseMove: (position) ->
    @_throttledMouseMoveHandler position

  _mouseMoveHandler: (position) ->
    # Determine which element we're hovering on.
    parentOrigin = @$appWindow.offset()

    for control in @_sortedControls
      hovering = control.isInside position, parentOrigin
      if hovering
        hoveredControl = control
        break

    # Only recompute things if we're not on the same control.
    unless hoveredControl is @hoveredControl
      # Hovered control is new. Calculate the new stack and add/remove hovered classes.
      @hoveredControl = hoveredControl

      oldHoveredStack = @_hoveredStack
      @_hoveredStack = []

      # We can only build the stack if we have a hovered control and it's inside our area.
      $element = hoveredControl?.$element
      if @$rootElement.has($element).length or @$rootElement.is($element)
        # Add all controls in this tree to the hovered stack.
        control = hoveredControl
        @_hoveredStack.push control

        while $element.parent().length
          $element = $element.parent()
          control = $element.data('control')
          @_hoveredStack.push control if control

      # Calculate difference sets.
      newlyHoveredControls = _.difference @_hoveredStack, oldHoveredStack
      unhoveredControls = _.difference oldHoveredStack, @_hoveredStack

      # Set newly hovered controls.
      for control in newlyHoveredControls
        control.hover = true
        control.$element.addClass('hover')

      # Remove unhovered controls.
      for control in unhoveredControls
        control.hover = false
        control.$element.removeClass('hover')

    # Send mouse move event.
    control.onMouseMove position for control in @_hoveredStack
    control.onGlobalMouseMove position for control in @_controls

  onMouseUp: (position, button) ->
    control.onMouseUp position, button for control in @_hoveredStack
    control.onGlobalMouseUp position, button for control in @_controls

  onMouseScroll: (delta) ->
    control.onMouseScroll delta for control in @_hoveredStack
