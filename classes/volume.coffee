'use strict'

class TopViewer.Volume
  constructor: (@options) ->
    height = @options.model.basePositionsTexture.image.height

    setVertexIndexCoordinates = (attribute, i, index) ->
      attribute.setX i, index % 4096 / 4096
      attribute.setY i, Math.floor(index / 4096) / height

    # Create the wireframe mesh.
    connectivity = []
    linesCount = 0

    addLine = (a, b) ->
      [a, b] = [b, a] if a > b

      connectivity[a] ?= {}
      unless connectivity[a][b]
        connectivity[a][b] = true
        linesCount++

    for i in [0...@options.elements.length/4]
      addLine(@options.elements[i*4], @options.elements[i*4+1])
      addLine(@options.elements[i*4+1], @options.elements[i*4+2])
      addLine(@options.elements[i*4+2], @options.elements[i*4])
      addLine(@options.elements[i*4], @options.elements[i*4+3])
      addLine(@options.elements[i*4+1], @options.elements[i*4+3])
      addLine(@options.elements[i*4+2], @options.elements[i*4+3])

    wireframeGeometry = new THREE.BufferGeometry()
    @wireframeMesh = new THREE.LineSegments wireframeGeometry, @options.model.volumeWireframeMaterial

    wireframeIndexArray = new Float32Array linesCount * 4
    wireframeIndexAttribute = new THREE.BufferAttribute wireframeIndexArray, 2

    lineVertexIndex = 0
    for a in [0...connectivity.length]
      continue unless connectivity[a]

      for b of connectivity[a]
        setVertexIndexCoordinates(wireframeIndexAttribute, lineVertexIndex, a)
        setVertexIndexCoordinates(wireframeIndexAttribute, lineVertexIndex + 1, b)
        lineVertexIndex += 2

    wireframeGeometry.addAttribute 'vertexIndex', wireframeIndexAttribute
    wireframeGeometry.drawRange.count = linesCount * 2

    # Create the isosurfaces mesh.
    isosurfacesGeometry = new THREE.BufferGeometry()
    @isosurfacesMesh = new THREE.Mesh isosurfacesGeometry, @options.model.isosurfaceMaterial
    tetraCount = @options.elements.length / 4

    # Each isosurface vertex needs access to all four tetra vertices.
    for i in [0..3]
      # The format of the array is, for each tetra: 6 * v[i]_x, v[i]_y
      isosurfacesIndexArray = new Float32Array tetraCount * 12
      isosurfacesIndexAttribute = new THREE.BufferAttribute isosurfacesIndexArray, 2

      # Add each tetra vertex (first, second, third or fourth, depending on i) to all 6 isovertices.
      for j in [0...tetraCount]
        for k in [0...6]
          setVertexIndexCoordinates(isosurfacesIndexAttribute, j*6+k, @options.elements[j * 4 + i])

      isosurfacesGeometry.addAttribute "vertexIndexCorner#{i+1}", isosurfacesIndexAttribute

    # We also need to tell the vertices what their index is and if they are part of the main or additional face.
    isosurfacesCornerIndexArray = new Float32Array tetraCount * 6
    isosurfacesCornerIndexAttribute = new THREE.BufferAttribute isosurfacesCornerIndexArray, 1

    for i in [0...tetraCount]
      for k in [0...6]
        isosurfacesCornerIndexArray[i * 6 + k] = k * 0.1

    isosurfacesGeometry.addAttribute "cornerIndex", isosurfacesCornerIndexAttribute

    isosurfacesGeometry.drawRange.count = tetraCount * 6

    # Finish creating geometry.
    @_updateGeometry()

    # Add the meshes to the model. Add wireframe last for better draw order when both are transparent.
    @options.model.add @isosurfacesMesh
    @options.model.add @wireframeMesh

    # Add the mesh to rendering controls.
    @options.engine.renderingControls.addVolume @options.name, @

  _updateGeometry: ->
    @_updateBounds @wireframeMesh, @options.model
    @_updateBounds @isosurfacesMesh, @options.model

  _updateBounds: (mesh, model) ->
    mesh.geometry.boundingBox = @options.model.boundingBox
    mesh.geometry.boundingSphere = @options.model.boundingSphere

  showFrame: () ->
    @wireframeMesh.visible = @options.engine.renderingControls.volumesShowWireframeControl.value()
    @isosurfacesMesh.visible = @options.engine.renderingControls.volumesShowIsosurfacesControl.value()

    @isosurfacesMesh.receiveShadows = true
    @isosurfacesMesh.castShadows = true
    #@isosurfacesMesh.receiveShadows = @options.engine.renderingControls.shadowsControl.value()
