'use strict'

class TopViewer.FileManager
  constructor: (@options) ->

  initialize: (fileListData) ->
    return unless @options.targetFile

    filenameStartIndex = @options.targetFile.lastIndexOf('/') + 1
    targetFolder = @options.targetFile.substring 0, filenameStartIndex

    # Scan the same folder as the target file and build the database.
    @urls = {}

    for file in fileListData.others
      url = file.sage2URL

      # Only include files in the same folder.
      fileFolder = url.substring 0, url.lastIndexOf('/') + 1
      continue unless targetFolder is fileFolder

      @urls[url] = new TopViewer.File url

    # We have built a list of files in the same folder. Now scan the files to generate objects.
    @objects =
      nodes: {}
      elements: {}
      vectors: {}
      scalars: {}

    @scalarLimits = {}

    @meshes = {}

    new TopViewer.ConcurrencyManager
      items: _.values @urls
      methodName: 'load'
      onProgress: (progress, item) =>
        #console.log "Loaded #{progress * 100}% of files."
        @_addObjects item.objects

      onComplete: =>
        #console.log "Loaded all the files!"

        # Ideally at this point the objects file should be empty!
        #console.log "Objects should be empty!", @objects
        #console.log "Meshes should be plentiful!", @meshes

  _addObjects: (objects) ->
    # Add nodes.
    for nodesName, nodesInstance of objects.nodes
      @objects.nodes[nodesName] = nodesInstance

    # Add elements.
    for elementsName, elementsInstance of objects.elements
      @objects.elements[elementsName] = elementsInstance

    # Add all scalars.
    for scalarNodesName, scalars of objects.scalars
      @objects.scalars[scalarNodesName] ?= {}
      for scalarName, scalar of scalars
        @objects.scalars[scalarNodesName][scalarName] = scalar

        # Create or get the global limits for this scalar.
        @scalarLimits[scalarName] ?=
          minValue: null
          maxValue: null
          version: 0

        limits = @scalarLimits[scalarName]

        # Update scalar limits.
        for frame in scalar.frames
          limits.minValue = frame.minValue unless limits.minValue? and limits.minValue < frame.minValue
          limits.maxValue = frame.maxValue unless limits.maxValue? and limits.maxValue > frame.maxValue

        # Set global limits to the scalar.
        scalar.limits = limits
        limits.version++

    # Add all vectors.
    for vectorNodesName, vectors of objects.vectors
      @objects.vectors[vectorNodesName] ?= {}
      for vectorName, vector of vectors
        @objects.vectors[vectorNodesName][vectorName] = vector

    @_processObjects()

  _processObjects: ->
    # Create all the meshes from nodes.
    for nodesName, nodesInstance of @objects.nodes
      @meshes[nodesName] = new TopViewer.Mesh
        engine: @options.engine

      @meshes[nodesName].setNodes nodesInstance
      delete @objects.nodes[nodesName]

    # Add element information to meshes
    for elementsName, elementsInstance of @objects.elements
      if @meshes[elementsInstance.nodesName]
        @meshes[elementsInstance.nodesName].addElements elementsInstance
        delete @objects.elements[elementsName]

    # Add all scalars.
    for scalarNodesName, scalars of @objects.scalars
      if @meshes[scalarNodesName]
        for scalarName, scalar of scalars
          @meshes[scalarNodesName].addScalar scalarName, scalar
        delete @objects.scalars[scalarNodesName]

    # Add all vectors.
    for vectorNodesName, vectors of @objects.vectors
      if @meshes[vectorNodesName]
        for vectorName, vector of vectors
          @meshes[vectorNodesName].addVector vectorName, vector
        delete @objects.vectors[vectorNodesName]
