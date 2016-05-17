'use strict'

class TopViewer.UIArea
  constructor: (@$appWindow) ->
    # Keep a list of controls on which to call events.
    @_controls = []

  destroy: ->
    @$appWindow = null
    control.destroy?() for control in @_controls
    @_controls = null

  addControl: (control) ->
    @_controls.push control

  onMouseDown: (position, button) -> control.onMouseDown position, button for control in @_controls

  onMouseMove: (position) ->
    control.onMouseMove position for control in @_controls

  onMouseUp: (position, button) ->
    control.onMouseUp position, button for control in @_controls
