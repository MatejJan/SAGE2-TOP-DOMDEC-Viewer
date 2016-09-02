'use strict'

class TopViewer.Gradient
  constructor: (@name, @url) ->
    @data = new Uint8Array 1024 * 4
    @texture = new THREE.DataTexture @data, 1024, 1, THREE.RGBAFormat, THREE.UnsignedByteType

    @image = new Image()
    @image.onload = =>
      canvas = document.createElement('canvas')
      canvas.width = 1024
      canvas.height = 1
      canvas.getContext('2d').drawImage @image, 0, 0, 1024, 1
      uintData = canvas.getContext('2d').getImageData(0, 0, 1024, 1).data
      @data[i] = uintData[i] for i in [0...uintData.length]
      @texture.needsUpdate = true

    # Initiate loading.
    @image.src = @url
