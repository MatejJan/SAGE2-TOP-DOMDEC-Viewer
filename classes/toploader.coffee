'use strict'

class TopViewer.TopLoader
  load: (options) ->
    worker = new Worker '/uploads/apps/top_viewer/classes/toploader-worker.js'

    worker.onmessage = (message) =>
      switch message.data.type
        when 'size'
          options.onSize? message.data.size

        when 'progress'
          options.onProgress? message.data.loadPercentage

        when 'result'
          options.onResults? message.data.objects

        when 'complete'
          options.onComplete?()

    worker.postMessage
      url: options.url
