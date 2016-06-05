'use strict'

class TopViewer.Engine

  constructor: (@options)->
    @scene = new TopViewer.Scene
      engine: @
      resourcesPath: @options.resourcesPath

    @camera = new THREE.PerspectiveCamera(45, @options.width / @options.height, 0.001, 100)
    @camera.position.z = 3

    @renderer = new THREE.WebGLRenderer
      antialias: true

    @renderer.setSize window.innerWidth, window.innerHeight
    @renderer.setClearColor 0x444550

    @renderer.shadowMap.enabled = true
    @renderer.shadowMap.type = THREE.PCFSoftShadowMap

    @$appWindow = @options.$appWindow
    @$appWindow.append @renderer.domElement

    proxyCube = new THREE.Mesh new THREE.BoxGeometry(1, 1, 1), new THREE.MeshLambertMaterial color: 0xeeeeee

    @cameraControls = new THREE.OrbitControls @camera, @renderer.domElement
    @cameraControls.minDistance = 0.05
    @cameraControls.maxDistance = 10
    @cameraControls.zoomSpeed = 0.5
    @cameraControls.rotateSpeed = 2
    @cameraControls.autoRotate = false
    @cameraControls.autoRotateSpeed = 2.0

    @rotateControls = new THREE.OrbitControls proxyCube, @renderer.domElement
    @rotateControls.enableZoom = false
    @rotateControls.enablePan = false
    @rotateControls.minDistance = 0.05
    @rotateControls.maxDistance = 10
    @rotateControls.rotateSpeed = 1
    @rotateControls.autoRotate = false
    @rotateControls.autoRotateSpeed = 2.0

    @objectRotation = new THREE.Matrix4

    @activeControls = @cameraControls

    @shadows = true
    @vertexColors = false
    @reflections = true
    @directionalLight = true
    @ambientLight = true

    @uiAreas = []

    @animation = new TopViewer.Animation
    @playbackControls = new TopViewer.PlaybackControls engine: @
    @renderingControls = new TopViewer.RenderingControls engine: @

    @uiAreas.push @playbackControls
    @uiAreas.push @renderingControls

    @_frameTime = 0
    @_frameCount = 0

    @gradientData = new Uint8Array 1024 * 4
    @gradientTexture = new THREE.DataTexture @gradientData, 1024, 1, THREE.RGBAFormat, THREE.UnsignedByteType
    @loadGradient @options.resourcesPath + 'gradients/xpost.png'

    @gradientCurveData = new Float32Array 4096
    @gradientCurveTexture = new THREE.DataTexture @gradientCurveData, 4096, 1, THREE.AlphaFormat, THREE.FloatType, THREE.UVMapping, THREE.ClampToEdgeWrapping, THREE.ClampToEdgeWrapping, THREE.LinearFilter, THREE.LinearFilter

  loadGradient: (url) ->
    image = new Image()
    image.onload = =>
      canvas = document.createElement('canvas')
      canvas.width = 1024
      canvas.height = 1
      canvas.getContext('2d').drawImage image, 0, 0, 1024, 1
      uintData = canvas.getContext('2d').getImageData(0, 0, 1024, 1).data
      @gradientData[i] = uintData[i] for i in [0...uintData.length]
      @gradientTexture.needsUpdate = true

    # Initiate loading.
    image.src = url

  destroy: ->
    @scene.destroy()
    @playbackControls.destroy()

  toggleShadows: ->
    @shadows = not @shadows
    @scene.update()

  toggleVertexColors: ->
    @vertexColors = not @vertexColors
    @scene.update()

  toggleReflections: ->
    @reflections = not @reflections
    @scene.update()

  toggleDirectionalLight: ->
    @directionalLight = not @directionalLight
    @scene.update()

  toggleAmbientLight: ->
    @ambientLight = not @ambientLight
    @scene.update()

  toggleSurface: ->
    @renderingControls.surfaceControl.setValue not @renderingControls.surfaceControl.value

  toggleWireframe: ->
    @renderingControls.wireframeControl.setValue not @renderingControls.wireframeControl.value

  resize: (width, height) ->
    @camera.aspect = width / height
    @camera.updateProjectionMatrix()
    @renderer.setSize width, height
    @renderer.setViewport 0, 0, @renderer.context.drawingBufferWidth, @renderer.context.drawingBufferHeight

  draw: (elapsedTime) ->
    @uiControlsActive = false

    for uiArea in @uiAreas
      @uiControlsActive = true if uiArea.rootControl.hover

    if @activeControls is @rotateControls
      @rotateControls.update()
      azimuthal = @rotateControls.getAzimuthalAngle()
      polar = -@rotateControls.getPolarAngle()
      euler = new THREE.Euler polar, azimuthal, 0, 'XYZ'
      @objectRotation = new THREE.Matrix4().makeRotationFromEuler euler
      @scene.updateRotation()

    else if @activeControls is @cameraControls
      @cameraControls.update()

    # Update gradient curve data.
    unless @_gradientMapLastUpdate is @renderingControls.gradientCurve.lastUpdated
      @_gradientMapLastUpdate = @renderingControls.gradientCurve.lastUpdated
      @gradientCurveData[i] = @renderingControls.gradientCurve.getY(i/4096) for i in [0...4096]
      @gradientCurveTexture.needsUpdate = true

    @playbackControls.update elapsedTime
    frameIndex = @playbackControls.currentFrameIndex
    frameTime = @animation.frameTimes[frameIndex] ? -1

    for model in @scene.children when model instanceof TopViewer.Model
      model.showFrame frameTime

    @renderer.render @scene, @camera

    @_frameCount++
    @_frameTime += elapsedTime

    if @_frameTime > 1
      #console.log "FPS:", @_frameCount
      @_frameCount = 0
      @_frameTime = 0

  onMouseDown: (position, button) ->
    @activeControls.mouseDown position.x, position.y, @buttonIndexFromString button unless @uiControlsActive

    uiArea.onMouseDown position, button for uiArea in @uiAreas

  onMouseMove: (position) ->
    @activeControls.mouseMove position.x, position.y unless @uiControlsActive

    uiArea.onMouseMove position for uiArea in @uiAreas

  onMouseUp: (position, button) ->
    @activeControls.mouseUp position.x, position.y, @buttonIndexFromString button unless @uiControlsActive

    uiArea.onMouseUp position, button for uiArea in @uiAreas

  onMouseScroll: (delta) ->
    @activeControls.scale delta unless @uiControlsActive

  buttonIndexFromString: (button) ->
    if (button == 'right') then 2 else 0
