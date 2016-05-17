'use strict'

importScripts '../libraries/three.min.js'

self.onmessage = (message) ->
  url = message.data.url
  loader = new THREE.XHRLoader @manager
  loader.setCrossOrigin message.data.crossOrigin
  loader.setResponseType 'arraybuffer'

  loader.load url, (text) =>
    worker = new PLYWorker message.data.propertyNameMapping
    postMessage
      type: 'result'
      buffers: worker.parse text

    close()

class PLYWorker
  constructor: (@propertyNameMapping) ->

  bin2str: (buf) ->
    array_buffer = new Uint8Array(buf)
    str = ''

    for i in [0...buf.byteLength]
      str += String.fromCharCode(array_buffer[i])
    # implicitly assumes little-endian

    str

  isASCII: (header) ->
    header.format is 'ascii'

  parse: (data) ->
    if data instanceof ArrayBuffer
      # Determine the size of the header.
      unicodeArray = new Uint8Array data
      endString = "end_header"

      endIndex = -1
      tryIndex = 0
      while endIndex < 0
        good = true
        for i in [0...endString.length]
          if String.fromCharCode(unicodeArray[tryIndex + i]) isnt endString[i]
            good = false
            break

        endIndex = tryIndex + endString.length + 1 if good
        tryIndex++

        # Give up after a while.
        return if tryIndex > 10000

      headerText = String.fromCharCode.apply null, new Uint8Array data, 0, endIndex

      header = @parseHeader headerText

      if @isASCII(header) then @parseASCII(@bin2str(data)) else @parseBinary(data, header)

    else
      @parseASCII data

  parseHeader: (data) ->
    patternHeader = /ply([\s\S]*)end_header\s/
    headerText = ''
    headerLength = 0
    result = patternHeader.exec(data)

    make_ply_element_property = (propertValues, propertyNameMapping) ->
      property = type: propertValues[0]
      if property.type == 'list'
        property.name = propertValues[3]
        property.countType = propertValues[1]
        property.itemType = propertValues[2]
      else
        property.name = propertValues[1]
      if property.name of propertyNameMapping
        property.name = propertyNameMapping[property.name]
      property

    if result != null
      headerText = result[1]
      headerLength = result[0].length

    header =
      comments: []
      elements: []
      headerLength: headerLength

    lines = headerText.split('\n')
    currentElement = undefined
    lineType = undefined
    lineValues = undefined

    for i in [0...lines.length]
      line = lines[i]
      line = line.trim()
      if line == ''
        continue

      lineValues = line.split(/\s+/)
      lineType = lineValues.shift()
      line = lineValues.join(' ')
      switch lineType
        when 'format'
          header.format = lineValues[0]
          header.version = lineValues[1]
        when 'comment'
          header.comments.push line
        when 'element'
          if !(currentElement == undefined)
            header.elements.push currentElement
          currentElement = Object()
          currentElement.name = lineValues[0]
          currentElement.count = parseInt(lineValues[1])
          currentElement.properties = []
        when 'property'
          currentElement.properties.push make_ply_element_property(lineValues, @propertyNameMapping)
        else
          console.log 'unhandled', lineType, lineValues

    if !(currentElement == undefined)
      header.elements.push currentElement
    header

  parseASCIINumber: (n, type) ->
    switch type
      when 'char', 'uchar', 'short', 'ushort', 'int', 'uint', 'int8', 'uint8', 'int16', 'uint16', 'int32', 'uint32'
        return parseInt(n)

      when 'float', 'double', 'float32', 'float64'
        return parseFloat(n)

  parseASCIIElement: (properties, line) ->
    values = line.split(/\s+/)
    element = Object()
    i = 0
    for i in [i...properties.length]
      if properties[i].type == 'list'
        list = []
        n = @parseASCIINumber(values.shift(), properties[i].countType)

        for j in [0...n]
          list.push @parseASCIINumber(values.shift(), properties[i].itemType)

        element[properties[i].name] = list
      else
        element[properties[i].name] = @parseASCIINumber(values.shift(), properties[i].type)

    element

  parseASCII: (data) ->
    # PLY ascii format specification, as per http://en.wikipedia.org/wiki/PLY_(file_format)
    geometry = new (THREE.Geometry)
    result = undefined
    header = @parseHeader(data)
    patternBody = /end_header\s([\s\S]*)$/
    body = ''
    if (result = patternBody.exec(data)) != null
      body = result[1]
    lines = body.split('\n')
    currentElement = 0
    currentElementCount = 0
    geometry.useColor = false
    i = 0
    for i in [0...lines.length]
      line = lines[i]
      line = line.trim()
      if line == ''
        continue

      if currentElementCount >= header.elements[currentElement].count
        currentElement++
        currentElementCount = 0
      element = @parseASCIIElement(header.elements[currentElement].properties, line)
      @handleElement geometry, header.elements[currentElement].name, element
      currentElementCount++

    @postProcess geometry

  postProcess: (geometry) ->
    geometry.computeBoundingSphere()
    geometry

  binaryRead: (dataReader, type, little_endian) ->
    switch type
    # corespondences for non-specific length types here match rply:
      when 'int8', 'char'
        value = dataReader.dataView.getInt8(dataReader.location)
        dataReader.location += 1
        return value

      when 'uint8', 'uchar'
        value = dataReader.dataView.getUint8(dataReader.location)
        dataReader.location += 1
        return value

      when 'int16', 'short'
        value = dataReader.dataView.getInt16(dataReader.location, little_endian)
        dataReader.location += 2
        return value

      when 'uint16', 'ushort'
        value = dataReader.dataView.getUint16(dataReader.location, little_endian)
        dataReader.location += 2
        return value

      when 'int32', 'int'
        value = dataReader.dataView.getInt32(dataReader.location, little_endian)
        dataReader.location += 4
        return value

      when 'uint32', 'uint'
        value = ataReader.dataView.getUint32(dataReader.location, little_endian)
        dataReader.location += 4
        return value

      when 'float32', 'float'
        value = dataReader.dataView.getFloat32(dataReader.location, little_endian)
        dataReader.location += 4
        return value

      when 'float64', 'double'
        value = dataReader.dataView.getFloat64(dataReader.location, little_endian)
        dataReader.location += 8
        return value

  parseBinary: (data, header) ->
    little_endian = header.format == 'binary_little_endian'

    # Prepare buffers into which to load the data.
    buffers = {}

    totalElements = 0
    completedElements = 0

    for element in header.elements
      totalElements += element.count
      switch element.name
        when 'vertex'
          for property in element.properties
            switch property.name
              when 'x', 'y', 'z'
                buffers.positions = new Float32Array element.count * 3

              when 'red', 'green', 'blue'
                buffers.colors = new Float32Array element.count * 3

        when 'face'
          buffers.indices = new Uint32Array element.count * 3

    dataReader =
      dataView: new DataView data, header.headerLength
      location: 0

    percentageChangeAt = Math.floor totalElements / 100

    for element in header.elements
      for i in [0...element.count]
        for property in element.properties
          if property.type is 'list'
            n = @binaryRead(dataReader, property.countType, little_endian)

            for j in [0...n]
              value = @binaryRead(dataReader, property.itemType, little_endian)
              buffers.indices[i * 3 + j] = value

          else
            value = @binaryRead(dataReader, property.type, little_endian)

            switch property.name
              when 'x' then buffers.positions[i * 3] = value
              when 'y' then buffers.positions[i * 3 + 1] = value
              when 'z' then buffers.positions[i * 3 + 2] = value
              when 'red' then buffers.colors[i * 3] = value / 255.0
              when 'green' then buffers.colors[i * 3 + 1] = value / 255.0
              when 'blue' then buffers.colors[i * 3 + 2] = value / 255.0

        completedElements++
        if completedElements % percentageChangeAt is 0
          postMessage
            type: 'progress'
            loadPercentage: 100.0 * completedElements / totalElements


    # Create geometry to calculate normals

    geometry = new THREE.BufferGeometry()
    geometry.addAttribute 'position', new THREE.BufferAttribute buffers.positions, 3 if buffers.positions
    geometry.setIndex new THREE.BufferAttribute buffers.indices, 1 if buffers.indices
    geometry.computeVertexNormals()

    buffers.normals = geometry.attributes.normal.array
    buffers

    buffers
