'use strict'

class TopViewer.Mesh extends THREE.Mesh
  constructor: (@options) ->
    super new THREE.BufferGeometry(), @options.engine.scene.modelMaterial
    @geometry.addAttribute 'position', @options.positionAttribute
    @geometry.addAttribute 'color', @options.colorAttribute
    @geometry.setIndex new THREE.BufferAttribute @options.elements, 1
    @_updateGeometry()

    # Add the mesh to the model.
    @options.model.add @

    # Notify the scene that there is a new mesh.
    @options.engine.scene.addMesh @

    # Add the mesh to rendering controls.
    @options.engine.renderingControls.addMesh @options.name, @

  _updateGeometry: ->
    @geometry.computeVertexNormals()
    @geometry.computeBoundingSphere()
    @geometry.computeBoundingBox()

    @options.engine.scene.acommodateMeshBounds @

  showFrame: () ->
    showSurface = @renderingControls.surface.value
    showWireframe = @renderingControls.wireframe.value

    # Create wireframe mesh if needed.
    if showWireframe and not @wireframeMesh
      @wireframeMesh = new THREE.Mesh @geometry, @options.engine.scene.wireframeMaterial
      @options.model.add @wireframeMesh

    @visible = showSurface
    @wireframeMesh?.visible = showWireframe

    @geometry.computeVertexNormals()
