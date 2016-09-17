'use strict'

class TopViewer.Vector
  constructor: (@options) ->
    height = @options.model.basePositionsTexture.image.height
    nodesCount = @options.model.nodes.length

    setVertexIndexCoordinates = (attribute, i, index) ->
      attribute.setX i, index % 4096 / 4096
      attribute.setY i, Math.floor(index / 4096) / height

    fieldGeometry = new THREE.BufferGeometry()
    @fieldMesh = new THREE.LineSegments fieldGeometry, @options.model.fieldMaterial

    # Create two vertices per node for starting and ending point of the vector arrow.
    fieldIndexArray = new Float32Array nodesCount * 4
    fieldIndexAttribute = new THREE.BufferAttribute fieldIndexArray, 2

    # We also need to tell the vertices if they are the start or the end of the arrow.
    vectorCornerIndexArray = new Float32Array nodesCount * 2
    vectorCornerIndexAttribute = new THREE.BufferAttribute vectorCornerIndexArray, 1

    for index in [0...nodesCount]
      for i in [0..1]
        setVertexIndexCoordinates fieldIndexAttribute, index * 2 + i, index
        vectorCornerIndexArray[index * 2 + i] = i

    fieldGeometry.addAttribute 'vertexIndex', fieldIndexAttribute
    fieldGeometry.addAttribute "cornerIndex", vectorCornerIndexAttribute
    fieldGeometry.drawRange.count = nodesCount * 2

    @_updateGeometry()
    
    @options.model.add @fieldMesh

  _updateGeometry: ->
    @_updateBounds @fieldMesh, @options.model

  _updateBounds: (mesh, model) ->
    mesh.geometry.boundingBox = @options.model.boundingBox
    mesh.geometry.boundingSphere = @options.model.boundingSphere

  showFrame: () ->
    @fieldMesh.visible = @options.engine.renderingControls.vectorsFieldVectorControl.value is @options.vector
