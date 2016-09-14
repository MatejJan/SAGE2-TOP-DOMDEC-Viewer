'use strict'

class TopViewer.FileManager extends TopViewer.UIArea
  constructor: (@options) ->
    super

    saveState = @options.engine.options.app.state.fileManager
    @$appWindow = @options.engine.$appWindow
    @scene = @options.engine.scene

    # Construct the html of rendering controls.
    @$manager = $("<div class='file-manager'>")
    @$appWindow.append @$manager

    # Set the roots.
    @$rootElement = @$manager
    @rootControl = new TopViewer.UIControl @, @$manager

    # Setup scrolling.
    scrollOffset = 0
    @rootControl.scroll (delta) =>
      scrollOffset += delta
      scrollOffset = Math.max scrollOffset, 0
      scrollOffset = Math.min scrollOffset, @$controls.height() - @options.engine.$appWindow.height() * 0.8

      @$controls.css
        top: -scrollOffset

    # Files

    @$filesArea = $("<ul class='files'></ul>")
    new TopViewer.ToggleContainer @,
      $parent: @$manager
      text: "Files"
      class: 'panel'
      visible: saveState.files.panelEnabled
      $contents: @$filesArea
      onChange: (value) =>
        saveState.files.panelEnabled = value

    @files = {}

    @initialize()

    @options.engine.uiAreas.push @

  addFile: (file) ->
    $file = $("<li class='file'></li>")
    @$filesArea.append($file)

    $contents = $("<div>")

    fileContainer = new TopViewer.ToggleContainer @,
      $parent: $file
      text: file.filename
      class: 'file-container'
      visible: false
      $contents: $contents

    $loadProgress = $('<span class="load-progress">')
    $name = fileContainer.toggleControl.$element.find('.name')
    $name.append($loadProgress)

    $fileSize = $('<span class="file-size">')
    $name.after($fileSize)

    file.options.onSize = (size) =>
      units = ['B', 'kB', 'MB', 'GB']
      unitIndex = 0
      while size > 100
        size /= 1000
        unitIndex++

      $fileSize.text "#{Math.round10(size, -1)}#{units[unitIndex]}"

    file.options.onProgress = (percentage) =>
      $loadProgress.css('width', "#{percentage}%")

    file.options.onComplete = =>
      $name.addClass('loaded')

  initializeFiles: (fileListData) ->
    return unless @options.targetFile

    filenameStartIndex = @options.targetFile.lastIndexOf('/') + 1
    targetFolder = @options.targetFile.substring 0, filenameStartIndex

    # Scan the same folder as the target file and build the database.
    @files = {}

    for fileData in fileListData.others
      url = fileData.sage2URL

      # Only include files in the same folder.
      fileFolder = url.substring 0, url.lastIndexOf('/') + 1
      continue unless targetFolder is fileFolder

      file = new TopViewer.File
        url: url
        onResults: (objects) =>
          @_addObjects objects

      @addFile file

      @files[url] = file

    # We have built a list of files in the same folder. Now scan the files to generate objects.
    @objects =
      nodes: {}
      elements: {}
      vectors: {}
      scalars: {}

    @scalarLimits = {}

    @models = {}

    new TopViewer.ConcurrencyManager
      items: _.values @files
      methodName: 'load'

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
    # Create all the models from nodes.
    for nodesName, nodesInstance of @objects.nodes
      @models[nodesName] = new TopViewer.Model
        engine: @options.engine
        nodes: nodesInstance.nodes

      delete @objects.nodes[nodesName]

    # Create meshes and volumes from elements.
    for elementsName, elementsInstance of @objects.elements
      if @models[elementsInstance.nodesName]
        for elementsType, elements of elementsInstance.elements
          @models[elementsInstance.nodesName].addElements elementsName, parseInt(elementsType), elements
          delete @objects.elements[elementsName]

    # Add all scalars.
    for scalarNodesName, scalars of @objects.scalars
      if @models[scalarNodesName]
        for scalarName, scalar of scalars
          @models[scalarNodesName].addScalar scalarName, scalar
        delete @objects.scalars[scalarNodesName]

    # Add all vectors.
    for vectorNodesName, vectors of @objects.vectors
      if @models[vectorNodesName]
        for vectorName, vector of vectors
          @models[vectorNodesName].addVector vectorName, vector
        delete @objects.vectors[vectorNodesName]
