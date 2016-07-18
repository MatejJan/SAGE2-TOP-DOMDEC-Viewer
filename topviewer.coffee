'use strict'

window.topviewer = SAGE2_App.extend
  init: (data) ->
    console.log "Top viewer started with data", data

    @SAGE2Init 'div', data
    @resizeEvents = 'continuous'

    targetFile = data.state.file

    @lastDrawTime = data.date.getTime() / 1000

    $element = $(@element)
    $element.append """
      <link href='https://fonts.googleapis.com/css?family=Ubuntu+Condensed' rel='stylesheet' type='text/css'>
      <link href="/uploads/apps/top_viewer/css/fontello.css" rel="stylesheet"/>
      <link href="/uploads/apps/top_viewer/css/animation.css" rel="stylesheet"/>
      <link rel="stylesheet" type="text/css" href="/uploads/apps/top_viewer/css/playbackcontrols.css" />
      <link rel="stylesheet" type="text/css" href="/uploads/apps/top_viewer/css/renderingcontrols.css" />
    """

    @engine = new TopViewer.Engine
      app: @
      width: @width
      height: @height
      $appWindow: $element
      resourcesPath: @resrcPath

    @fileManager = new TopViewer.FileManager
      targetFile: targetFile
      engine: @engine

    @needsResize = data.date

    # Start the draw loop.
    @_shouldQuit = false
    @drawLoop()

    # Be prepared to receive the file list.
    @storedFileListEventHandler = (fileListData) =>
      @fileManager.initialize fileListData

    addStoredFileListEventHandler @storedFileListEventHandler

  load: (date) ->
    #your load code here- update app based on this.state

  draw: (date) ->
    @needsDraw = date

  resize: (date) ->
    @needsResize = date

  drawLoop: ->
    requestAnimationFrame =>
      @drawLoop() unless @_shouldQuit

    if (@needsResize)
      @width = @element.clientWidth
      @height = @element.clientHeight

      @engine.resize @width, @height

      $(@element).css
        fontSize: @height * 0.015

      @refresh @needsResize
      @needsResize = false

    if (@needsDraw)
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

          when 83 # S
            @engine.toggleSurface()

          when 67 # C
            @engine.activeControls = @engine.cameraControls

          when 79 # O
            @engine.activeControls = @engine.rotateControls

          when 82 # R
            @engine.toggleReflections()

          when 65 # A
            @engine.toggleAmbientLight()

          when 68 # D
            @engine.toggleDirectionalLight()

          when 86 # V
            @engine.toggleVertexColors()

          when 87 # W
            @engine.toggleWireframe()

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

  move: (date) ->
    # this.sage2_width, this.sage2_height give width and height of app in global wall coordinates
    # date: when it happened
    @refresh date

  quit: ->
    console.log "Destroying topViewer"

    # Clean up EVERYTHING!
    @_shouldQuit = true
    removeStoredFileListEventHandler @storedFileListEventHandler

    @engine.destroy()
    @engine = null

    # It's the end
    @log 'Done'
