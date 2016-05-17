'use strict'

class TopViewer.PLYLoader
  load: (url, onLoad, onProgress, onError) ->
    worker = new Worker '/uploads/apps/top_viewer/classes/plyloader-worker.js'

    worker.onmessage = (message) =>
      switch message.data.type
        when 'progress'
          onProgress message.data.loadPercentage if onProgress

        when 'result'
          onProgress 100 if onProgress
    
          buffers = message.data.buffers

          geometry = new THREE.BufferGeometry()
          geometry.addAttribute 'position', new THREE.BufferAttribute buffers.positions, 3 if buffers.positions
          geometry.addAttribute 'normal', new THREE.BufferAttribute buffers.normals, 3 if buffers.normals
          geometry.addAttribute 'color', new THREE.BufferAttribute buffers.colors, 3 if buffers.colors
          geometry.setIndex new THREE.BufferAttribute buffers.indices, 1 if buffers.indices
          geometry.computeBoundingSphere()
          geometry.computeBoundingBox()

          onLoad geometry

    worker.postMessage
      url: url
      propertyNameMapping: @propertyNameMapping
