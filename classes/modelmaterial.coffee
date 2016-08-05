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

        lightDirection:
          type: 'v3'
          value: new THREE.Vector3(1,-2,1).normalize()

        ambientLevel:
          type: 'f'
          value: 0

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
attribute vec2 vertexIndex2;
attribute vec2 vertexIndex3;
attribute vec2 vertexIndex4;

varying float scalar;
varying vec3 normal;

void main()	{
  vec4 positionData = texture2D(basePositionsTexture, vertexIndex);
  vec3 vertexPosition = positionData.xyz;

  vec4 positionData2 = texture2D(basePositionsTexture, vertexIndex2);
  vec3 vertexPosition2 = positionData2.xyz;

  vec4 positionData3 = texture2D(basePositionsTexture, vertexIndex3);
  vec3 vertexPosition3 = positionData3.xyz;

  vec4 positionData4 = texture2D(basePositionsTexture, vertexIndex4);
  vec3 vertexPosition4 = positionData4.xyz;

  if (displacementFactor > 0.0) {
    positionData = texture2D(displacementsTexture, vertexIndex);
    vertexPosition += positionData.xyz * displacementFactor;

    positionData2 = texture2D(displacementsTexture, vertexIndex2);
    vertexPosition2 += positionData2.xyz * displacementFactor;

    positionData3 = texture2D(displacementsTexture, vertexIndex3);
    vertexPosition3 += positionData3.xyz * displacementFactor;

    positionData4 = texture2D(displacementsTexture, vertexIndex4);
    vertexPosition4 += positionData4.xyz * displacementFactor;
  }

  if (scalarsRange > 0.0) {
    scalar = clamp((texture2D(scalarsTexture, vertexIndex).a - scalarsMin) / scalarsRange, 0.01, 0.99);
  } else {
    scalar = -1.0;
  }

  vec3 tangent1 = normalize(vertexPosition2 - vertexPosition3);
  vec3 tangent2 = normalize(vertexPosition4 - vertexPosition2);

  normal = cross(tangent1, tangent2);

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
uniform vec3 lightDirection;
uniform float ambientLevel;
uniform float opacity;

varying float scalar;
varying vec3 normal;

void main()	{
  vec3 baseColor;
  float shade = ambientLevel + (1.0 - ambientLevel) * max(dot(lightDirection, normal), 0.0);
  shade = 1.0;

  if (scalar >= 0.0) {
    float curvedScalar = texture2D(gradientCurveTexture, vec2(scalar, 0)).a;
    baseColor = texture2D(gradientTexture, vec2(curvedScalar, 0)).rgb;
  } else {
    baseColor = color;
  }

  gl_FragColor = vec4(shade * baseColor, opacity);
}
"""
