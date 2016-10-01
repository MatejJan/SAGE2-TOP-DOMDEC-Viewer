'use strict'

class TopViewer.Engine

  constructor: (@options)->
    @scene = new TopViewer.Scene
      engine: @
      resourcesPath: @options.resourcesPath

    @camera = new THREE.PerspectiveCamera(45, @options.app.sage2_width / @options.app.sage2_height, 0.001, 20)

    cameraState = @options.app.state.camera
    @camera.position.copy cameraState.position
    @camera.rotation.set cameraState.rotation._x, cameraState.rotation._y, cameraState.rotation._z, cameraState.rotation._order
    @camera.scale.set cameraState.scale.x, cameraState.scale.y, cameraState.scale.z

    @renderer = new THREE.WebGLRenderer
      antialias: true
      canvas: @options.app.canvas

    @renderer.setSize window.innerWidth, window.innerHeight
    @renderer.setClearColor 0x444550

    @renderer.shadowMap.enabled = true
    @renderer.shadowMap.type = THREE.PCFSoftShadowMap
    @renderer.shadowMap.renderSingleSided = false

    @$appWindow = @options.$appWindow
    @$appWindow.append @renderer.domElement

    @_proxyCamera = new THREE.PerspectiveCamera(45, @options.width / @options.height, 0.01, 20)

    objectState = @options.app.state.object
    @_proxyCamera.position.copy objectState.position
    @_proxyCamera.rotation.set objectState.rotation._x, objectState.rotation._y, objectState.rotation._z, objectState.rotation._order
    @_proxyCamera.scale.set objectState.scale.x, objectState.scale.y, objectState.scale.z

    @cameraControls = new THREE.OrbitControls @camera, @options.app.element
    @cameraControls.minDistance = 0.01
    @cameraControls.maxDistance = 10
    @cameraControls.zoomSpeed = 0.5
    @cameraControls.rotateSpeed = 2
    @cameraControls.autoRotate = false
    @cameraControls.center.copy cameraState.center

    @rotateControls = new THREE.OrbitControls @_proxyCamera, @options.app.element
    @rotateControls.minDistance = 0.01
    @rotateControls.maxDistance = 10
    @rotateControls.rotateSpeed = 1
    @rotateControls.autoRotate = false
    @updateRotateControls()

    @activeControls = @cameraControls

    @lightingPresets = [
      new TopViewer.LightingSetup 'Angled light', new THREE.Vector3(0.8, 1, 0.9).normalize()
      new TopViewer.LightingSetup 'Top light', new THREE.Vector3(0.1, 1, 0.2).normalize()
      new TopViewer.LightingSetup 'Front light', new THREE.Vector3(0.2, 0.1, 1).normalize()
      new TopViewer.LightingSetup 'Side light', new THREE.Vector3(1, 0.1, 0.2).normalize()
    ]

    @gradients = [
      new TopViewer.Gradient "Spectrum", "#{@options.resourcesPath}gradients/spectrum.png"
      new TopViewer.Gradient "Monochrome", "#{@options.resourcesPath}gradients/monochrome.png"
      new TopViewer.Gradient "Dual", "#{@options.resourcesPath}gradients/dual.png"
      new TopViewer.Gradient "Fire", "#{@options.resourcesPath}gradients/heat.png"
      new TopViewer.Gradient "Classic", "#{@options.resourcesPath}gradients/xpost.png"
    ]

    @uiAreas = []

    @animation = new TopViewer.Animation engine: @
    @playbackControls = new TopViewer.PlaybackControls engine: @
    @renderingControls = new TopViewer.RenderingControls engine: @

    @uiAreas.push @playbackControls
    @uiAreas.push @renderingControls

    @_frameTime = 0
    @_frameCount = 0

  destroy: ->
    @scene.destroy()
    @playbackControls.destroy()

  resize: (resizeData) ->
    @renderer.setSize @options.app.canvas.width, @options.app.canvas.height

    @camera.setViewOffset @options.app.sage2_width, @options.app.sage2_height,
      resizeData.leftViewOffset, resizeData.topViewOffset,
      resizeData.localWidth, resizeData.localHeight

  draw: (elapsedTime) ->
    @uiControlsActive = false

    @rotateControls.update()

    for uiArea in @uiAreas
      @uiControlsActive = true if uiArea.rootControl.hover

    if @activeControls is @rotateControls
      @updateRotateControls()

    else if @activeControls is @cameraControls
      @cameraControls.update()

    TopViewer.CurveTransformControl.update()

    # Update lights.
    @scene.directionalLight.position.copy @renderingControls.lightingSetupControl.value.lightPosition
    @scene.ambientLight.intensity = @renderingControls.ambientLevelControl.value

    @playbackControls.update elapsedTime
    frameIndex = @playbackControls.currentFrameIndex
    nextFrameIndex = @playbackControls.currentFrameIndex + 1

    frameTime = @animation.frameTimes[frameIndex] ? -1
    nextFrameTime = @animation.frameTimes[nextFrameIndex] ? -1
    
    frameProgress = @playbackControls.currentTime - @playbackControls.currentFrameIndex

    for model in @scene.children when model instanceof TopViewer.Model
      model.showFrame frameTime, nextFrameTime, frameProgress

    @renderer.render @scene, @camera

    @_frameCount++
    @_frameTime += elapsedTime

    # Sync clients every second.
    if @_frameTime > 1
      #console.log "FPS:", @_frameCount
      @_frameCount = 0
      @_frameTime = 0
      if window.isMaster
        @options.app.broadcast 'sync',
          currentTime: @playbackControls.currentTime
          playing: @playbackControls.playing
          state: @options.app.state

  updateRotateControls: ->
    @rotateControls.update()
    azimuthal = @rotateControls.getAzimuthalAngle()
    polar = -@rotateControls.getPolarAngle()
    euler = new THREE.Euler polar, azimuthal, 0, 'XYZ'
    @objectRotation = new THREE.Matrix4().makeRotationFromEuler euler
    @scene.updateRotation()

  onMouseDown: (position, button) ->
    @activeControls.mouseDown position.x, position.y, @buttonIndexFromString button unless @uiControlsActive
    @_updateSaveState()

    uiArea.onMouseDown position, button for uiArea in @uiAreas

  onMouseMove: (position) ->
    @activeControls.mouseMove position.x, position.y unless @uiControlsActive
    @_updateSaveState()

    uiArea.onMouseMove position for uiArea in @uiAreas

  onMouseUp: (position, button) ->
    @activeControls.mouseUp position.x, position.y, @buttonIndexFromString button unless @uiControlsActive
    @_updateSaveState()

    uiArea.onMouseUp position, button for uiArea in @uiAreas

  onMouseScroll: (delta) ->
    @activeControls.scale delta unless @uiControlsActive
    @_updateSaveState()

    uiArea.onMouseScroll delta for uiArea in @uiAreas

  buttonIndexFromString: (button) ->
    if (button == 'right') then 2 else 0

  _updateSaveState: ->
    @options.app.state.camera = _.pick @camera, 'position', 'rotation', 'scale'
    @options.app.state.camera.center = @cameraControls.center

    @options.app.state.object = _.pick @_proxyCamera, 'position', 'rotation', 'scale'
