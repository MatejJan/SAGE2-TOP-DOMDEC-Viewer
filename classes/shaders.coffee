class TopViewer.Shaders
  @wireframeFragmentShader: """
#{TopViewer.ShaderChunks.commonFragment}
#{TopViewer.ShaderChunks.vertexMaterialFragment}

void main()	{
  #{TopViewer.ShaderChunks.vertexMaterialBaseColor}

  gl_FragColor = vec4(baseColor, opacity);
}
"""

  @surfaceFragmentShader: """
#{TopViewer.ShaderChunks.commonFragment}
#{TopViewer.ShaderChunks.vertexMaterialFragment}
#{TopViewer.ShaderChunks.surfaceMaterialFragment}

// Shadow map
#define SHADOWMAP_TYPE_PCF_SOFT 1
#{THREE.ShaderChunk.common}
#{THREE.ShaderChunk.packing}
#{THREE.ShaderChunk.lights_pars}
#{THREE.ShaderChunk.shadowmap_pars_fragment}

void main()	{
  #{TopViewer.ShaderChunks.vertexMaterialBaseColor}

  // Start with the light level at ambient and add all directional lights.
  vec3 light = vec3(0.0);
  DirectionalLight directionalLight;

  for (int i=0; i < NUM_DIR_LIGHTS; i++) {
    directionalLight = directionalLights[i];

    // Shade using Lambert cosine law.
    float shade = dot(-directionalLight.direction, normalEye);

    // Bidirectional lights act from both direction, otherwise the light is only the positive part.
    if (lightingBidirectional > 0.5) {
      shade = abs(shade);
    } else {
      shade = max(shade, 0.0);
    }

    // Apply shadowmaps. For some reason (bug) we must address the map with a constant, not the index i.
    if (i==0) {
      shade *= getShadow(directionalShadowMap[0], directionalLight.shadowMapSize, directionalLight.shadowBias, directionalLight.shadowRadius, vDirectionalShadowCoord[0]);
    }

#if NUM_DIR_LIGHTS > 1
    else if (i==1) {
      shade *= getShadow(directionalShadowMap[1], directionalLight.shadowMapSize, directionalLight.shadowBias, directionalLight.shadowRadius, vDirectionalShadowCoord[1]);
    }
#endif

    // Add the shaded amount of light's color to the total light.
    light += directionalLight.color * shade;
  }

  // Raise by the ambient level.
  light = mix(light, vec3(1.0), ambientLightColor);

  // Finally apply the light to the base color and output it with desired opacity.
  gl_FragColor = vec4(baseColor * light, opacity);
}
"""
