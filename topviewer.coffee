'use strict'

window.topviewer = SAGE2_WebGLApp.extend
  init: (data) ->
    console.log "Top viewer started with data", data

    @WebGLAppInit 'canvas', data
    @resizeEvents = 'continuous'

    targetFile = data.state.file

    $element = $(@element)
    $element.addClass('top-viewer')
    $element.append """
      <link href='https://fonts.googleapis.com/css?family=Ubuntu+Condensed' rel='stylesheet' type='text/css'>
      <link href="/uploads/apps/top_viewer/css/fontello.css" rel="stylesheet"/>
      <link href="/uploads/apps/top_viewer/css/animation.css" rel="stylesheet"/>
      <link rel="stylesheet" type="text/css" href="/uploads/apps/top_viewer/css/ui.css" />
      <link rel="stylesheet" type="text/css" href="/uploads/apps/top_viewer/css/filemanager.css" />
      <link rel="stylesheet" type="text/css" href="/uploads/apps/top_viewer/css/playbackcontrols.css" />
      <link rel="stylesheet" type="text/css" href="/uploads/apps/top_viewer/css/renderingcontrols.css" />
    """

    @engine = new TopViewer.Engine
      app: @
      $appWindow: $element
      resourcesPath: @resrcPath

    @fileManager = new TopViewer.FileManager
      targetFile: targetFile
      engine: @engine

    # Be prepared to receive the file list.
    @storedFileListEventHandler = (fileListData) =>
      @fileManager.initializeFiles fileListData

    addStoredFileListEventHandler @storedFileListEventHandler

    this.resizeCanvas()

    # Start the draw loop.
    @_shouldQuit = false
    @lastDrawTime = data.date.getTime() / 1000
    this.refresh data.date
    @drawLoop()

  sync: (data) ->
    unless window.isMaster
      # Sync time.
      @engine.playbackControls.setCurrentTime data.currentTime
      if data.playing then @engine.playbackControls.play() else @engine.playbackControls.pause()

      # Sync camera.
      cameraState = data.state.camera
      @engine.camera.position.copy cameraState.position
      @engine.camera.rotation.set cameraState.rotation._x, cameraState.rotation._y, cameraState.rotation._z, cameraState.rotation._order
      @engine.camera.scale.set cameraState.scale.x, cameraState.scale.y, cameraState.scale.z
      @engine.cameraControls.center.copy cameraState.center

  animationUpdate: (data) ->
    # We are receiving updated frame length from one of the display clients.
    @engine.animation.onAnimationUpdate data if data.clientId?

    # The master is sending us new max length.
    @engine.animation.length = data.maxLength if data.maxLength?

  renderingControlsUpdateClientObjects: (data) ->
    @engine.renderingControls.updateClientObjects data

  resizeApp: (resizeData) ->
    @engine.resize resizeData

    $(@element).css
      fontSize: @sage2_height * 0.015
      
  startMove: (date) ->
    @moving = true

  move: (date) ->
    @resizeCanvas date
    @refresh date

    @moving = false

  draw: (date) ->
    @needsDraw = date

  drawLoop: ->
    requestAnimationFrame =>
      @drawLoop() unless @_shouldQuit

    if (@needsDraw)
      # Do continuous resizes of underlying canvas when moving (since new crop sizes need to be applied).
      if @moving
        @resizeCanvas date
        @refresh date

      date = @needsDraw
      time = date.getTime() / 1000
      elapsedTime = time - @lastDrawTime

      @engine.draw elapsedTime
      @needsDraw = false
      @lastDrawTime = time

  event: (eventType, position, user_id, data, date) ->
    if eventType == 'pointerPress'
      @engine.onMouseDown position, data.button
      @refresh date
    else if eventType == 'pointerMove'
      @engine.onMouseMove position
      @refresh date
    else if eventType == 'pointerRelease'
      @engine.onMouseUp position, data.button
      @refresh date
    if eventType == 'pointerScroll'
      @engine.onMouseScroll data.wheelDelta
      @refresh date
    if eventType == 'keyboard'
      if data.character == ' '
        @engine.playbackControls.togglePlay()
        @refresh date
    if eventType == 'specialKey'
      if data.state is 'down'
        switch data.code
          when 37 # Left
            @engine.playbackControls.previousFrame()

          when 39 # Right
            @engine.playbackControls.nextFrame()

          when 67 # C
            @engine.activeControls = @engine.cameraControls

          when 79 # O
            @engine.activeControls = @engine.rotateControls

        @refresh date
    else if eventType == 'widgetEvent'
      switch data.identifier
        when 'Up'
          # up
          @engine.orbitControls.pan 0, @engine.orbitControls.keyPanSpeed
          @engine.orbitControls.update()
        when 'Down'
          # down
          @engine.orbitControls.pan 0, -@engine.orbitControls.keyPanSpeed
          @engine.orbitControls.update()
        when 'Left'
          # left
          @engine.orbitControls.pan @engine.orbitControls.keyPanSpeed, 0
          @engine.orbitControls.update()
        when 'Right'
          # right
          @engine.orbitControls.pan -@engine.orbitControls.keyPanSpeed, 0
          @engine.orbitControls.update()
        when 'ZoomIn'
          @engine.orbitControls.scale 4
        when 'ZoomOut'
          @engine.orbitControls.scale -4
        when 'Loop'
          @rotating = !@rotating
          @engine.orbitControls.autoRotate = @rotating
        else
          console.log 'No handler for:', data.identifier
          return

      @refresh date

  quit: ->
    console.log "Destroying topViewer"

    # Clean up EVERYTHING!
    @_shouldQuit = true
    removeStoredFileListEventHandler @storedFileListEventHandler

    @engine.destroy()
    @engine = null

    # It's the end.
    @log 'Done'
