class TopViewer.File
  @loaders =
    top: new TopViewer.TopLoader

  # Re-use top for alternative xpost extension.
  @loaders.xpost = @loaders.top

  constructor: (@url) ->
    @filename = @url.split('/').pop()
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

    @loader.load @url, (@objects) =>
      onCompleteHandler()
    ,
      (loadPercentage) =>
        #console.log "Loaded #{loadPercentage}% of #{@filename}." if loadPercentage % 10 is 0
