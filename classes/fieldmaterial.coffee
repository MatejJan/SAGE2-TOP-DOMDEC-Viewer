'use strict'

class TopViewer.FieldMaterial extends TopViewer.VertexMaterial
  constructor: (@model) ->
    super @model,

      uniforms:
        unitLength:
          value: 1

        vectorTexture:
          value: TopViewer.Model.noDisplacementsTexture

        vectorTextureNext:
          value: TopViewer.Model.noDisplacementsTexture

      vertexShader: """
#{TopViewer.ShaderChunks.commonVertex}
#{TopViewer.ShaderChunks.positionsMaterialVertex}
#{TopViewer.ShaderChunks.vertexMaterialVertex}

uniform sampler2D vectorTexture;
uniform sampler2D vectorTextureNext;
uniform float unitLength;
uniform float opacity;

attribute vec2 vertexIndex;
attribute float cornerIndex;

varying float alpha;

void main()	{
  vec4 positionData = texture2D(basePositionsTexture, vertexIndex);
  vec3 vertexPosition = positionData.xyz;

  if (displacementFactor > 0.0) {
    positionData = texture2D(displacementsTexture, vertexIndex);
    vec4 positionDataNext = texture2D(displacementsTextureNext, vertexIndex);
    positionData = mix(positionData, positionDataNext, frameProgress);

    vertexPosition += positionData.xyz * displacementFactor;
  }

  alpha = opacity;

  if (cornerIndex > 0.5) {
    vec4 vectorData = texture2D(vectorTexture, vertexIndex);
    vec4 vectorDataNext = texture2D(vectorTextureNext, vertexIndex);
    vectorData = mix(vectorData, vectorDataNext, frameProgress);

    vertexPosition += vectorData.xyz * unitLength;

    alpha = 0.0;
  }

  #{TopViewer.ShaderChunks.vertexMaterialScalar}

  gl_Position = projectionMatrix * modelViewMatrix * vec4(vertexPosition, 1.0);
}
"""

      fragmentShader: """
#{TopViewer.ShaderChunks.commonFragment}
#{TopViewer.ShaderChunks.vertexMaterialFragment}

varying float alpha;

void main()	{
  #{TopViewer.ShaderChunks.vertexMaterialBaseColor}

  gl_FragColor = vec4(baseColor, alpha);
}
"""
