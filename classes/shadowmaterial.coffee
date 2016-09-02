'use strict'

class TopViewer.ShadowMaterial extends TopViewer.PositionsMaterial
  constructor: (@model) ->
    super @model,

      vertexShader: """
precision highp float;
precision highp int;

uniform mat4 viewMatrix;
uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;

uniform float frameProgress;

uniform sampler2D basePositionsTexture;
uniform sampler2D displacementsTexture;
uniform sampler2D displacementsTextureNext;
uniform float displacementFactor;

uniform float time;

attribute vec2 vertexIndexCorner1;
attribute vec2 vertexIndexCorner2;
attribute vec2 vertexIndexCorner3;
attribute float cornerIndex;

void main()	{
  vec2 vertexIndices[3];
  vertexIndices[0] = vertexIndexCorner1;
  vertexIndices[1] = vertexIndexCorner2;
  vertexIndices[2] = vertexIndexCorner3;

  // Start by calculating all 3 triangle corners and the normal of the triangle.
  vec3 vertexPositions[3];

  for (int i=0; i<3; i++) {
    vec4 positionData = texture2D(basePositionsTexture, vertexIndices[i]);
    vertexPositions[i] = positionData.xyz;

    if (displacementFactor > 0.0) {
      positionData = texture2D(displacementsTexture, vertexIndices[i]);
      vec4 positionDataNext = texture2D(displacementsTextureNext, vertexIndices[i]);
      positionData = mix(positionData, positionDataNext, frameProgress);

      vertexPositions[i] += positionData.xyz * displacementFactor;
    }
  }

  // Determine which corner we're currently at and pass its position to the fragment shader.
  vec2 vertexIndex;
  vec3 vertexPosition;

  if (cornerIndex < 0.05) {vertexIndex = vertexIndices[0]; vertexPosition = vertexPositions[0];}
  else if (cornerIndex < 0.15) {vertexIndex = vertexIndices[1]; vertexPosition = vertexPositions[1];}
  else {vertexIndex = vertexIndices[2]; vertexPosition = vertexPositions[2];}

  gl_Position = projectionMatrix * modelViewMatrix * vec4(vertexPosition, 1.0);
}
"""

      fragmentShader: """
precision highp float;
precision highp int;

uniform float time;

#{THREE.ShaderChunk.packing}

void main()	{
  gl_FragColor = packDepthToRGBA(gl_FragCoord.z);
}
"""
