'use strict'

class TopViewer.Scene extends THREE.Scene
  constructor: (options) ->
    super()

    @engine = options.engine

    @ambientLight = new THREE.AmbientLight 0xffffff, 0
    @add @ambientLight

    @directionalLight = @addShadowedLight 0, 1, 0, 0xffffff, 1

    @planeMaterial = new THREE.MeshLambertMaterial
      color: 0x444550

    @plane = new THREE.PlaneGeometry(20, 20)
    @floor = new THREE.Mesh @plane, @planeMaterial
    @floor.rotation.x = -Math.PI * 0.5
    @floor.rotation.z = -Math.PI * 0.5
    @floor.receiveShadow = true
    @floor.castShadow = false
    @add @floor

    @normalizationMatrix = new THREE.Matrix4()
    @rotationMatrix = new THREE.Matrix4()
    @scaleMatrix = new THREE.Matrix4()
    @translationMatrix = new THREE.Matrix4()

    @_currentFrameSet = []

    @sceneBoundingBox = new THREE.Box3 new THREE.Vector3(), new THREE.Vector3()

  destroy: ->
    @remove @children...
    @planeMaterial.dispose()

  addShadowedLight: (x, y, z, color, intensity) ->
    directionalLight = new THREE.DirectionalLight color, intensity
    directionalLight.position.set x, y, z

    directionalLight.castShadow = true
    directionalLight.shadow = new THREE.LightShadow new THREE.OrthographicCamera -2, 2, 2, -2, 0.1, 5
    directionalLight.shadow.mapSize.width = 4096
    directionalLight.shadow.mapSize.height = 4096
    directionalLight.shadow.bias = -0.002

    @add directionalLight

    directionalLight

  addModel: (model) ->
    model.matrix = @normalizationMatrix
    @add model

    @sceneBoundingBox = @sceneBoundingBox.union model.boundingBox
    @updateScale()
    @updateTranslation()

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
    @floor.position.y = minY - 0.001

  _recomputeNormalizationMatrix: ->
    @normalizationMatrix.copy @rotationMatrix
    @normalizationMatrix.multiply @scaleMatrix
    @normalizationMatrix.multiply @translationMatrix
