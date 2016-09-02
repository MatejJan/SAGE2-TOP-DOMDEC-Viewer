'use strict'

class TopViewer.WireframeMaterial extends TopViewer.VertexMaterial
  constructor: (@model) ->
    super @model,

      vertexShader: """
#{TopViewer.ShaderChunks.commonVertex}
#{TopViewer.ShaderChunks.positionsMaterialVertex}
#{TopViewer.ShaderChunks.vertexMaterialVertex}

attribute vec2 vertexIndex;

void main()	{
  vec4 positionData = texture2D(basePositionsTexture, vertexIndex);
  vec3 vertexPosition = positionData.xyz;

  if (displacementFactor > 0.0) {
    positionData = texture2D(displacementsTexture, vertexIndex);
    vec4 positionDataNext = texture2D(displacementsTextureNext, vertexIndex);
    positionData = mix(positionData, positionDataNext, frameProgress);

    vertexPosition += positionData.xyz * displacementFactor;
  }

  #{TopViewer.ShaderChunks.vertexMaterialScalar}

  gl_Position = projectionMatrix * modelViewMatrix * vec4(vertexPosition, 1.0);
}
"""

      fragmentShader: TopViewer.Shaders.wireframeFragmentShader
