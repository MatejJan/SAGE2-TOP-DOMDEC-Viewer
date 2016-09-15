'use strict'

class TopViewer.PositionsMaterial extends THREE.RawShaderMaterial
  constructor: (@model, options) ->
    options.uniforms or= {}

    _.extend options.uniforms,
      # Because vector results change with time (we have multiple frames), we do linear interpolation of displacement
      # between current and next frame, controlled by the frame progress scalar.
      frameProgress:
        value: 0

      # Positions are calculated by the sum of base node positions and displacements from a vector result. We can
      # amplify the displacement with the displacement factor scalar.
      basePositionsTexture:
        value: @model.basePositionsTexture

      displacementsTexture:
        value: TopViewer.Model.noDisplacementsTexture

      displacementsTextureNext:
        value: TopViewer.Model.noDisplacementsTexture

      displacementFactor:
        value: 0

      # Time is right now only included to be used in debugging scenarios.
      time:
        value: 0

    super options

class TopViewer.VertexMaterial extends TopViewer.PositionsMaterial
  constructor: (@model, options) ->
    options.uniforms or= {}

    _.extend options.uniforms,
      # Base vertex colors can be set to a constant color or it can come from scalar results. Scalars are transformed
      # using the curve function and then mapped onto a color gradient using the provided value range.
      vertexColor:
        value: new THREE.Color 'white'

      vertexScalarsTexture:
        value: TopViewer.Model.noScalarsTexture

      vertexScalarsTextureNext:
        value: TopViewer.Model.noScalarsTexture

      vertexScalarsMin:
        value: 0

      vertexScalarsRange:
        value: 0

      vertexScalarsCurveTexture:
        value: TopViewer.Model.noCurveTexture

      vertexScalarsGradientTexture:
        value: @model.options.engine.gradients[0].texture

      # Finally, opacity controls how visible the whole material is.
      opacity:
        value: 1

    super @model, options

class TopViewer.SurfaceMaterial extends TopViewer.VertexMaterial
  constructor: (@model, options) ->
    options.uniforms or= {}

    _.extend options.uniforms,
      # Lighting setup determines the shading applied to the base vertex colors. Ambient level controls the darkest
      # shade used, the rest of the range is covered based on simple lambert law based on calculated face normals.
      # Bidirectional light is used to illuminate the model from both the positive end negative light direction and
      # normal factor can be used to flip the lighting when rendering double-sided surfaces with two single-sided
      # meshes.
      lightingBidirectional:
        value: 0

      lightingNormalFactor:
        value: 1
    ,
      THREE.UniformsLib.lights

    options.defines or= {}

    _.extend options.defines,
      USE_SHADOWMAP: ''

    _.extend options,
      side: THREE.FrontSide
      lights: true

    super @model, options

class TopViewer.IsovalueMaterial extends TopViewer.VertexMaterial
  constructor: (@model, options) ->
    options.uniforms or= {}

    _.extend options.uniforms,
      scalarsTexture:
        value: TopViewer.Model.noScalarsTexture

      scalarsTextureNext:
        value: TopViewer.Model.noScalarsTexture

      scalarsCurveTexture:
        value: TopViewer.Model.noCurveTexture

      scalarsMin:
        value: 0

      scalarsRange:
        value: 0

    super @model, options
