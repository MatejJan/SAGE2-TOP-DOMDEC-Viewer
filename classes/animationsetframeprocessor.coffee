'use strict'

class THREE.AnimationSetFrameProcessor
  process: (frame, onLoad, onProgress, onError) ->
    worker = new Worker '/uploads/apps/mesh_viewer/classes/animationsetframeprocessor-worker.js'

    worker.onmessage = (message) =>
      switch message.data.type
        when 'progress'
          onProgress message.data.loadPercentage if onProgress

        when 'result'
          onProgress 100 if onProgress

          buffers = message.data.buffers

          geometry = new THREE.BufferGeometry()
          geometry.addAttribute 'position', new THREE.BufferAttribute buffers.positions, 3
          geometry.addAttribute 'color', new THREE.BufferAttribute buffers.colors, 3
          geometry.setIndex new THREE.BufferAttribute buffers.indices, 1
          geometry.computeVertexNormals()
          geometry.computeBoundingSphere()
          geometry.computeBoundingBox()

          onLoad geometry

    worker.postMessage
      frame: frame
