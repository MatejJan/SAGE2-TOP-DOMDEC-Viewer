'use strict'

class TopViewer.ModelMaterial extends TopViewer.SurfaceMaterial
  constructor: (@model) ->
    super @model,
      
      vertexShader: """
#{TopViewer.ShaderChunks.commonVertex}
#{TopViewer.ShaderChunks.positionsMaterialVertex}
#{TopViewer.ShaderChunks.vertexMaterialVertex}
#{TopViewer.ShaderChunks.surfaceMaterialVertex}

attribute vec2 vertexIndexCorner1;
attribute vec2 vertexIndexCorner2;
attribute vec2 vertexIndexCorner3;
attribute float cornerIndex;

#{THREE.ShaderChunk.shadowmap_pars_vertex}

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

  vec3 tangent1 = vertexPositions[0] - vertexPositions[1];
  vec3 tangent2 = vertexPositions[2] - vertexPositions[0];
  vec3 normal = normalize(cross(tangent1, tangent2)) * lightingNormalFactor;

  // Determine which corner we're currently at and pass its position to the fragment shader.
  vec2 vertexIndex;
  vec3 vertexPosition;

  if (cornerIndex < 0.05) {vertexIndex = vertexIndices[0]; vertexPosition = vertexPositions[0];}
  else if (cornerIndex < 0.15) {vertexIndex = vertexIndices[1]; vertexPosition = vertexPositions[1];}
  else {vertexIndex = vertexIndices[2]; vertexPosition = vertexPositions[2];}

  vec4 worldPosition = modelMatrix * vec4(vertexPosition, 1.0);
  gl_Position = projectionMatrix * viewMatrix * worldPosition;

  #{TopViewer.ShaderChunks.vertexMaterialScalar}

  // Pass on the normal and in view space.
  normalEye = normalize((modelViewMatrix * vec4(normal, 0.0)).xyz);

  // Shadowmap
  #{THREE.ShaderChunk.shadowmap_vertex}
}
"""

      fragmentShader: TopViewer.Shaders.surfaceFragmentShader