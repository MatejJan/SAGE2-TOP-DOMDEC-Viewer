'use strict'

class TopViewer.Mesh extends THREE.Mesh
  constructor: (@options) ->
    super new THREE.BufferGeometry(), @options.model.material

    # Create the surface mesh. We need 3 index arrays so each vertex knows
    # who its two face neighbors are, to calculate normals in the shader.
    indexArrays = []
    indexAttributes = []
    for i in [0..3]
      indexArrays[i] = new Float32Array @options.elements.length * 2
      indexAttributes[i] = new THREE.BufferAttribute indexArrays[i], 2

    height = @options.model.basePositionsTexture.image.height

    setVertexIndexCoordinates = (attribute, i, index) ->
      attribute.setX i, index % 4096 / 4096
      attribute.setY i, Math.floor(index / 4096) / height

    for i in [0...@options.elements.length]
      setVertexIndexCoordinates(indexAttributes[0], i, @options.elements[i])

      # Create normal indices.
      baseIndex = Math.floor(i/3) * 3
      indexInTriangle = i % 3

      for j in [0..2]
        setVertexIndexCoordinates(indexAttributes[indexInTriangle+1], baseIndex + j, @options.elements[i])

    @geometry.addAttribute 'vertexIndex', indexAttributes[0]
    @geometry.addAttribute 'vertexIndex2', indexAttributes[1]
    @geometry.addAttribute 'vertexIndex3', indexAttributes[2]
    @geometry.addAttribute 'vertexIndex4', indexAttributes[3]

    console.log indexArrays

    @geometry.drawRange.count = @options.elements.length

    # Create the wireframe mesh.
    connectivity = []
    linesCount = 0

    addLine = (a, b) ->
      [a, b] = [b, a] if a > b

      connectivity[a] ?= {}
      unless connectivity[a][b]
        connectivity[a][b] = true
        linesCount++

    for i in [0...@options.elements.length/3]
      addLine(@options.elements[i*3], @options.elements[i*3+1])
      addLine(@options.elements[i*3+1], @options.elements[i*3+2])
      addLine(@options.elements[i*3+2], @options.elements[i*3])

    wireframeGeometry = new THREE.BufferGeometry()
    @wireframeMesh = new THREE.LineSegments wireframeGeometry, @options.model.wireframeMaterial

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

    # Create the isolines mesh.
    isolinesGeometry = new THREE.BufferGeometry()
    @isolinesMesh = new THREE.LineSegments isolinesGeometry, @options.model.isolineMaterial
    faceCount = @options.elements.length / 3

    # Each isoline vertex needs access to all three face vertices.
    for i in [0..2]
      # The format of the array is, for each face: v[i]_x, v[i]_y, v[i]_x, v[i]_y
      isolinesIndexArray = new Float32Array faceCount * 4
      isolinesIndexAttribute = new THREE.BufferAttribute isolinesIndexArray, 2

      # Add each face vertex (first, second or third, depending on i) to the start and end isovertex.
      for j in [0...faceCount]
        for k in [0...2]
          setVertexIndexCoordinates(isolinesIndexAttribute, j*2+k, @options.elements[j * 3 + i])

      isolinesGeometry.addAttribute "vertex#{i+1}Index", isolinesIndexAttribute

    # We also need to tell the vertices if they are the start or the end of the isoline.
    isolinesTypeArray = new Float32Array faceCount * 2
    isolinesTypeAttribute = new THREE.BufferAttribute isolinesTypeArray, 1

    for i in [0...faceCount]
      isolinesTypeArray[i * 2 + 1] = 1.0

    isolinesGeometry.addAttribute "vertexType", isolinesTypeAttribute

    isolinesGeometry.drawRange.count = faceCount * 2

    # Finish creating geometry.
    @_updateGeometry()

    # Add the meshes to the model.
    @options.model.add @
    @options.model.add @wireframeMesh
    @options.model.add @isolinesMesh

    # Notify the scene that there is a new mesh.
    @options.engine.scene.addMesh @

    # Add the mesh to rendering controls.
    @options.engine.renderingControls.addMesh @options.name, @

  _updateGeometry: ->
    @_updateBounds @, @options.model
    @_updateBounds @wireframeMesh, @options.model
    @_updateBounds @isolinesMesh, @options.model

  _updateBounds: (mesh, model) ->
    mesh.geometry.boundingBox = @options.model.boundingBox
    mesh.geometry.boundingSphere = @options.model.boundingSphere

  showFrame: () ->
    @visible = @renderingControls.surface.value
    @wireframeMesh.visible = @renderingControls.wireframe.value
    @isolinesMesh.visible = @renderingControls.isolines.value
