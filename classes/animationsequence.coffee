'use strict'

class TopViewer.AnimationSequence extends TopViewer.Animation
  constructor: (@options) ->
    super

    @loaders =
      ply: new THREE.PLYLoader @options.loadingManager
      hive: new THREE.HiveLoader @options.loadingManager

    @length = @options.endFrame - @options.startFrame + 1

  load: ->
    @options.playbackControls.load()

    for frameNumber in [@options.startFrame..@options.endFrame]
      do (frameNumber) =>
        frame =
          loaded: false
          loadPercentage: 0
          normalized: false
          ready: false

        frameIndex = frameNumber - @options.startFrame
        @frames[frameIndex] = frame

        frameName = "#{frameNumber}"
        if @options.frameNumberLength
          while frameName.length < @options.frameNumberLength
            frameName = "0#{frameName}"

        frame.filename = @options.filename.replace '#', frameName

        extension = frame.filename.split('.').pop()
        frame.loader = @loaders[extension]

        if @onLoadProgress
          frame.onLoadProgressHandler = (loadPercentage) =>
            @onLoadProgress frameIndex, loadPercentage

    @_nextFrameToLoad = 0
    @_concurentFramesLoading = 0
    @processLoadQueue()

  processLoadQueue: ->
    return unless @_nextFrameToLoad?

    # Stop if loading is paused.
    return unless @options.playbackControls.loading

    # Stop when we reach the end of the frames.
    return if @_nextFrameToLoad >= @frames.length

    # Don't load if we're at the limit of concurrent loads.
    return if @maxConcurrentFramesLoading and @_concurentFramesLoading >= @maxConcurrentFramesLoading

    frame = @frames[@_nextFrameToLoad]

    frame.loader.load frame.filename, (geometry) =>
      geometry.name = frame.filename
      mesh = new THREE.Mesh geometry, @options.scene.modelMaterial
      mesh.matrixAutoUpdate = false
      mesh.castShadow = true

      frame.mesh = mesh
      frame.loaded = true

      @normalizeMeshes()
      @updateAnimation()

      @options.scene.addFrame frame

      # We have completed loading this frame so try to load a new one.
      @_concurentFramesLoading--
      @processLoadQueue()

    , frame.onLoadProgressHandler

    # Increment frames.
    @_nextFrameToLoad++
    @_concurentFramesLoading++

    # Keep on loading so we hit the concurrency limit.
    @processLoadQueue()
