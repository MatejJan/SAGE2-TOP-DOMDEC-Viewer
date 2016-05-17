class TopViewer.File
  @loaders =
    ply: new TopViewer.PLYLoader
    hive: new TopViewer.HiveLoader
    top: new TopViewer.TopLoader

  constructor: (@url) ->
    @extension = @url.split('.').pop()

    @loader = @constructor.loaders[@extension]

  load: (onCompleteHandler) ->
    @loader.load @url, (@objects) =>
      onCompleteHandler()
