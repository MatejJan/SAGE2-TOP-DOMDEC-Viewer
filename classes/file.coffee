class TopViewer.File
  @loaders =
    top: new TopViewer.TopLoader

  # Re-use top for alternative xpost extension.
  @loaders.xpost = @loaders.top

  constructor: (@options) ->
    @filename = @options.url.split('/').pop()
    @extension = @filename.split('.').pop()

    @loader = @constructor.loaders[@extension]

  load: (onCompleteHandler) ->
    # Simulate a dummy load if we don't have a loader for the file.
    unless @loader
      setTimeout =>
        @objects = {}
        onCompleteHandler()
      , 0

      return

    @loader.load
      url: @options.url,
      onSize: (size) =>
        @options.onSize? size

      onProgress: (loadPercentage) =>
        @options.onProgress? loadPercentage

      onResults: (@objects) =>
        # Trigger file onLoad event.
        @options.onResults? @objects

      onComplete: =>
        @options.onComplete?()

        # Report to the concurrency manager that we have finished execution.
        onCompleteHandler()
