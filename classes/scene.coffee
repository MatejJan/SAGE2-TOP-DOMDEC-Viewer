'use strict'

class TopViewer.Scene extends THREE.Scene
  constructor: (options) ->
    super()

    @engine = options.engine

    # Create the fancy scene.
    @skyLight = new THREE.HemisphereLight 0x92b6ee, 0x333333, 0.8
    @add @skyLight

    @whiteLight = new THREE.AmbientLight 0xffffff
    @add @whiteLight

    @directionalLight = @addShadowedLight 0.2, 1, 0.3, 0xeadbad, 1

    @planeMaterial = new THREE.MeshBasicMaterial
      color: 0x444550

    @modelMaterial = new THREE.MeshLambertMaterial
      color: 0xffffff
      vertexColors: THREE.VertexColors
      side: THREE.DoubleSide
      combine: THREE.MultiplyOperation
      reflectivity: 0.3

    @wireframeMaterial = new THREE.MeshBasicMaterial
      color: 0xffffff
      opacity: 0.5
      transparent: true
      side: THREE.DoubleSide
      wireframe: true

    @plane = new THREE.PlaneGeometry(20, 20)
    @floor = new THREE.Mesh @plane, @planeMaterial
    @floor.rotation.x = -Math.PI * 0.5
    @floor.rotation.z = -Math.PI * 0.5
    @floor.receiveShadow = true;
    @add @floor

    @normalizationMatrix = new THREE.Matrix4()
    @rotationMatrix = new THREE.Matrix4()
    @scaleMatrix = new THREE.Matrix4()
    @translationMatrix = new THREE.Matrix4()

    @_currentFrameSet = []

    @sceneBoundingBox = new THREE.Box3 new THREE.Vector3(), new THREE.Vector3()

  destroy: ->
    @remove @children...
    @modelMaterial.dispose()
    @planeMaterial.dispose()

  addShadowedLight: (x, y, z, color, intensity) ->
    directionalLight = new THREE.DirectionalLight color, intensity
    directionalLight.position.set x, y, z
    @add directionalLight

    directionalLight.castShadow = true
    # directionalLight.shadowCameraVisible = true;
    d = 3
    directionalLight.shadowCameraLeft = -d
    directionalLight.shadowCameraRight = d
    directionalLight.shadowCameraTop = d
    directionalLight.shadowCameraBottom = -d
    directionalLight.shadowCameraNear = 0.0005
    directionalLight.shadowCameraFar = 50
    directionalLight.shadowMapWidth = 1024
    directionalLight.shadowMapHeight = 1024
    directionalLight.shadowDarkness = 0.8
    #directionalLight.shadowBias = -0.001

    directionalLight

  showFrameSet: (frameSet) ->
    #console.log "showing frame set"

    frameSet ?= []

    # Hide frames in the current set.
    frame.mesh.visible = false for frame in @_currentFrameSet

    # Show frames in the new set.
    frame.mesh.visible = true for frame in frameSet

    wireframe = @engine.renderingControls.wireframeControl.value

    if wireframe
      for frame in @_currentFrameSet
        frame.wireframeMesh?.visible = false

      for frame in frameSet
        @generateWireframeMesh frame
        frame.wireframeMesh.visible = true

    #console.log "setting current frame set", frameSet

    @_currentFrameSet = frameSet

    @update()

  acommodateMeshBounds: (mesh) ->
    @sceneBoundingBox = @sceneBoundingBox.union mesh.geometry.boundingBox
    @updateScale()
    @updateTranslation()

  addModel: (model) ->
    model.matrix = @normalizationMatrix
    @add model
    @update()

  addMesh: (mesh) ->
    @update()

  update: ->
    for model in @children when model instanceof TopViewer.Model
      for mesh in model.meshes
        mesh.castShadow = @engine.shadows

    @directionalLight.visible = @engine.directionalLight
    @whiteLight.visible = not @engine.ambientLight
    @skyLight.visible = @engine.ambientLight

    materialNeedsUpdate = false

    if @engine.vertexColors isnt @_vertexColor
      @modelMaterial.vertexColors = if @engine.vertexColors then THREE.VertexColors else THREE.NoColors
      @_vertexColor = @engine.vertexColors
      materialNeedsUpdate = true

    @modelMaterial.needsUpdate = true if materialNeedsUpdate

  updateScale: ->
    # Normalize meshes by bringing the size of the bounding box down to 1.
    sceneBoundingBoxDiagonal = new THREE.Vector3().subVectors @sceneBoundingBox.max, @sceneBoundingBox.min
    scaleFactor = 2 / sceneBoundingBoxDiagonal.length()

    # Only continue if the scale factor changes over 50%
    if @_scaleFactor
      relativeChange = @_scaleFactor / scaleFactor
      return if relativeChange < 1.5

    @_scaleFactor = scaleFactor

    @scaleMatrix.makeScale scaleFactor, scaleFactor, scaleFactor

    @_recomputeNormalizationMatrix()
    @_updateFloor()

  updateRotation: ->
    @rotationMatrix.copy @engine.objectRotation
    @_recomputeNormalizationMatrix()

  updateTranslation: ->
    center = @sceneBoundingBox.center().clone()

    if @_centerDistance
      relativeChange = @_centerDistance / center.length()
      return if 0.5 < relativeChange < 1.5

    @_centerDistance = center.length()

    center.negate()

    @translationMatrix.makeTranslation center.x, center.y, center.z
    @_recomputeNormalizationMatrix()
    @_updateFloor()

  _updateFloor: ->
    center = @sceneBoundingBox.center().clone()
    center.negate()

    # Move floor underneath all meshes.
    minY = (@sceneBoundingBox.min.y + center.y) * @_scaleFactor
    @floor.position.y = minY

  _recomputeNormalizationMatrix: ->
    @normalizationMatrix.copy @rotationMatrix
    @normalizationMatrix.multiply @scaleMatrix
    @normalizationMatrix.multiply @translationMatrix
