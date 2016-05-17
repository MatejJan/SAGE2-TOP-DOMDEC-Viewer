'use strict'

class TopViewer.HiveLoader
  constructor: (manager) ->
    @manager = manager or THREE.DefaultLoadingManager

  setCrossOrigin: (value) ->
    @crossOrigin = value

  load: (url, onLoad, onProgress, onError) ->
    worker = new Worker '/uploads/apps/top_viewer/classes/hiveloader-worker.js'

    worker.onmessage = (message) =>
      switch message.data.type
        when 'progress'
          onProgress message.data.loadPercentage if onProgress

        when 'result'
          onProgress 100 if onProgress
          objects = message.data.objects
          #console.log "read file", url, objects
          onLoad objects

    worker.postMessage
      url: url
      crossOrigin: @crossOrigin
      propertyNameMapping: @propertyNameMapping
