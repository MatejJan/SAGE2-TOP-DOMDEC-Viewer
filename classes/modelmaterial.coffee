'use strict'

class TopViewer.ModelMaterial extends THREE.RawShaderMaterial
  constructor: (@model) ->
    super
      uniforms:
        basePositionsTexture:
          type: 't'
          value: @model.basePositionsTexture

        displacementsTexture:
          type: 't'
          value: @model.displacementsTexture

        displacementFactor:
          type: 'f'
          value: 0

        scalarsTexture:
          type: 't'
          value: @model.scalarsTexture

        scalarsMin:
          type: 'f'
          value: 0

        scalarsRange:
          type: 'f'
          value: 0

        gradientTexture:
          type: 't'
          value: @model.options.engine.gradientTexture

        gradientCurveTexture:
          type: 't'
          value: @model.options.engine.gradientCurveTexture

        time:
          type: 'f'
          value: 0

        color:
          type: 'c'
          value: new THREE.Color('white')

        opacity:
          type: 'f'
          value: 1

      side: THREE.DoubleSide

      vertexShader: """
precision highp float;
precision highp int;

uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;

uniform sampler2D basePositionsTexture;

uniform sampler2D displacementsTexture;
uniform float displacementFactor;

uniform sampler2D scalarsTexture;
uniform float scalarsMin;
uniform float scalarsRange;

uniform float time;

attribute vec2 vertexIndex;

varying float scalar;

void main()	{
  vec4 positionData = texture2D(basePositionsTexture, vertexIndex);
  vec3 vertexPosition = positionData.xyz;

  if (displacementFactor > 0.0) {
    positionData = texture2D(displacementsTexture, vertexIndex);
    vertexPosition += positionData.xyz * displacementFactor;
  }

  if (scalarsRange > 0.0) {
    scalar = clamp((texture2D(scalarsTexture, vertexIndex).a - scalarsMin) / scalarsRange, 0.01, 0.99);
  } else {
    scalar = -1.0;
  }

  gl_Position = projectionMatrix * modelViewMatrix * vec4(vertexPosition, 1.0);
}
"""

      fragmentShader: """
precision highp float;
precision highp int;

uniform sampler2D gradientCurveTexture;
uniform sampler2D gradientTexture;

uniform float time;
uniform vec3 color;
uniform float opacity;

varying float scalar;

void main()	{
  if (scalar >= 0.0) {
    float curvedScalar = texture2D(gradientCurveTexture, vec2(scalar, 0)).a;
    gl_FragColor = vec4(texture2D(gradientTexture, vec2(curvedScalar, 0)).rgb, opacity);
  } else {
    gl_FragColor = vec4(color, opacity);
  }
}
"""
