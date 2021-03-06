// Generated by CoffeeScript 1.10.0
(function() {
  'use strict';
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  TopViewer.ModelMaterial = (function(superClass) {
    extend(ModelMaterial, superClass);

    function ModelMaterial(model) {
      this.model = model;
      ModelMaterial.__super__.constructor.call(this, this.model, {
        vertexShader: TopViewer.ShaderChunks.commonVertex + "\n" + TopViewer.ShaderChunks.positionsMaterialVertex + "\n" + TopViewer.ShaderChunks.vertexMaterialVertex + "\n" + TopViewer.ShaderChunks.surfaceMaterialVertex + "\n\nattribute vec2 vertexIndexCorner1;\nattribute vec2 vertexIndexCorner2;\nattribute vec2 vertexIndexCorner3;\nattribute float cornerIndex;\n\n" + THREE.ShaderChunk.shadowmap_pars_vertex + "\n\nvoid main()	{\n  vec2 vertexIndices[3];\n  vertexIndices[0] = vertexIndexCorner1;\n  vertexIndices[1] = vertexIndexCorner2;\n  vertexIndices[2] = vertexIndexCorner3;\n\n  // Start by calculating all 3 triangle corners and the normal of the triangle.\n  vec3 vertexPositions[3];\n\n  for (int i=0; i<3; i++) {\n    vec4 positionData = texture2D(basePositionsTexture, vertexIndices[i]);\n    vertexPositions[i] = positionData.xyz;\n\n    if (displacementFactor > 0.0) {\n      positionData = texture2D(displacementsTexture, vertexIndices[i]);\n      vec4 positionDataNext = texture2D(displacementsTextureNext, vertexIndices[i]);\n      positionData = mix(positionData, positionDataNext, frameProgress);\n\n      vertexPositions[i] += positionData.xyz * displacementFactor;\n    }\n  }\n\n  vec3 tangent1 = vertexPositions[0] - vertexPositions[1];\n  vec3 tangent2 = vertexPositions[2] - vertexPositions[0];\n  vec3 normal = normalize(cross(tangent1, tangent2)) * lightingNormalFactor;\n\n  // Determine which corner we're currently at and pass its position to the fragment shader.\n  vec2 vertexIndex;\n  vec3 vertexPosition;\n\n  if (cornerIndex < 0.05) {vertexIndex = vertexIndices[0]; vertexPosition = vertexPositions[0];}\n  else if (cornerIndex < 0.15) {vertexIndex = vertexIndices[1]; vertexPosition = vertexPositions[1];}\n  else {vertexIndex = vertexIndices[2]; vertexPosition = vertexPositions[2];}\n\n  vec4 worldPosition = modelMatrix * vec4(vertexPosition, 1.0);\n  gl_Position = projectionMatrix * viewMatrix * worldPosition;\n\n  " + TopViewer.ShaderChunks.vertexMaterialScalar + "\n\n  // Pass on the normal and in view space.\n  normalEye = normalize((modelViewMatrix * vec4(normal, 0.0)).xyz);\n\n  // Shadowmap\n  " + THREE.ShaderChunk.shadowmap_vertex + "\n}",
        fragmentShader: TopViewer.Shaders.surfaceFragmentShader
      });
    }

    return ModelMaterial;

  })(TopViewer.SurfaceMaterial);

}).call(this);

//# sourceMappingURL=modelmaterial.js.map
