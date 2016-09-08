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

    # We need to reinitialize any time new controls are added after the first initialization.
    @initialize() if @_initialized

  # This must be called at the end of the constructor in the inherited UI area.
  initialize: ->
    @_initialized = true

    # We need to allow the DOM to be rendered.
    setTimeout =>
      # Create the ordered list of all controls in their rendering order. We will use
      # this on mouse move to determine which control the mouse is hovering over.

      # We start by creating an ordered list of all the elements, which we'll later filter to just the controls.
      sortedElements = []

      addElements = ($element) =>
        # When we have children, they should be sorted by z-index.
        children = $element.children().toArray()

        if children
          children = for child in children
            $child = $(child)
            zIndex = $child.css('z-index')

            if zIndex is 'auto'
              zIndex = 0

            else
              zIndex = parseInt zIndex

            zIndex: zIndex
            element: $child

          children.sort (a, b) =>
            b.zIndex - a.zIndex

          # Now the elements get added from top-one down.
          addElements child.element for child in children

        # Finally add the element itself as well.
        sortedElements.push $element

      # Recursively add all elements in the UI area.
      addElements @$rootElement

      # Now filter this down to controls.
      @_sortedControls = []

      for $element in sortedElements
        control = $element.data('control')
        @_sortedControls.push control if control
    ,
      0

  onMouseDown: (position, button) ->
    control.onMouseDown position, button for control in @_hoveredStack

  onMouseMove: (position) ->
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
