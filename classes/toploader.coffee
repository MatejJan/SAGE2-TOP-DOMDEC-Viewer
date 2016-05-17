'use strict'

class TopViewer.TopLoader
  load: (url, onLoad, onProgress, onError) ->
    worker = new Worker '/uploads/apps/top_viewer/classes/toploader-worker.js'

    worker.onmessage = (message) =>
      switch message.data.type
        when 'progress'
          onProgress message.data.loadPercentage if onProgress

        when 'result'
          #console.log "Received", url
          objects = message.data.objects
          onLoad objects

    worker.postMessage
      url: url
