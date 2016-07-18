'use strict'

class TopViewer.IsosurfaceMaterial extends THREE.RawShaderMaterial
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
          value: 0.5

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

uniform sampler2D gradientCurveTexture;

uniform float time;

attribute vec2 vertex1Index;
attribute vec2 vertex2Index;
attribute vec2 vertex3Index;
attribute vec2 vertex4Index;
attribute float vertexType;

varying float scalar;

const float isostep = 0.1;

void main()	{
  scalar = -1.0;

  if (scalarsRange > 0.0) {
    vec3 vertex1Position = texture2D(basePositionsTexture, vertex1Index).xyz;
    vec3 vertex2Position = texture2D(basePositionsTexture, vertex2Index).xyz;
    vec3 vertex3Position = texture2D(basePositionsTexture, vertex3Index).xyz;
    vec3 vertex4Position = texture2D(basePositionsTexture, vertex4Index).xyz;

    if (displacementFactor > 0.0) {
      vertex1Position += texture2D(displacementsTexture, vertex1Index).xyz * displacementFactor;
      vertex2Position += texture2D(displacementsTexture, vertex2Index).xyz * displacementFactor;
      vertex3Position += texture2D(displacementsTexture, vertex3Index).xyz * displacementFactor;
      vertex4Position += texture2D(displacementsTexture, vertex4Index).xyz * displacementFactor;
    }

    float scalar1 = clamp((texture2D(scalarsTexture, vertex1Index).a - scalarsMin) / scalarsRange, 0.01, 0.99);
    float scalar2 = clamp((texture2D(scalarsTexture, vertex2Index).a - scalarsMin) / scalarsRange, 0.01, 0.99);
    float scalar3 = clamp((texture2D(scalarsTexture, vertex3Index).a - scalarsMin) / scalarsRange, 0.01, 0.99);
    float scalar4 = clamp((texture2D(scalarsTexture, vertex4Index).a - scalarsMin) / scalarsRange, 0.01, 0.99);
    float curvedScalar1 = texture2D(gradientCurveTexture, vec2(scalar1, 0)).a;
    float curvedScalar2 = texture2D(gradientCurveTexture, vec2(scalar2, 0)).a;
    float curvedScalar3 = texture2D(gradientCurveTexture, vec2(scalar3, 0)).a;
    float curvedScalar4 = texture2D(gradientCurveTexture, vec2(scalar4, 0)).a;

    for (float isovalue=0.0;isovalue<1.0;isovalue+=isostep) {
      bool above1 = curvedScalar1 > isovalue;
      bool above2 = curvedScalar2 > isovalue;
      bool above3 = curvedScalar3 > isovalue;
      bool above4 = curvedScalar4 > isovalue;
      int aboveCount = 0;
      if (above1) aboveCount++;
      if (above2) aboveCount++;
      if (above3) aboveCount++;
      if (above4) aboveCount++;

      if (aboveCount==0 || aboveCount==4) {
        continue;
      } else {
        vec3 leftPosition;
        vec3 rightPosition;
        float leftScalar;
        float rightScalar;

        if (aboveCount==2) {
          // Case with two triangles.
          if (vertexType < 0.05) {
            // Vertex 1
            if (above1 != above2) {
              leftPosition = vertex1Position;
              rightPosition =vertex2Position;
              leftScalar = curvedScalar1;
              rightScalar = curvedScalar2;
            } else {
              leftPosition = vertex1Position;
              rightPosition =vertex3Position;
              leftScalar = curvedScalar1;
              rightScalar = curvedScalar3;
            }
          } else if (vertexType < 0.15) {
            // Vertex 2
            if (above2 != above4) {
              leftPosition = vertex2Position;
              rightPosition =vertex4Position;
              leftScalar = curvedScalar2;
              rightScalar = curvedScalar4;
            } else {
              leftPosition = vertex2Position;
              rightPosition =vertex3Position;
              leftScalar = curvedScalar2;
              rightScalar = curvedScalar3;
            }
          } else if (vertexType < 0.25) {
            // Vertex 3
            if (above1 != above4) {
              leftPosition = vertex1Position;
              rightPosition =vertex4Position;
              leftScalar = curvedScalar1;
              rightScalar = curvedScalar4;
            } else {
              leftPosition = vertex1Position;
              rightPosition =vertex3Position;
              leftScalar = curvedScalar1;
              rightScalar = curvedScalar3;
            }
          } else if (vertexType < 0.35) {
            // Vertex extra 1
            if (above1 != above3) {
              leftPosition = vertex1Position;
              rightPosition =vertex3Position;
              leftScalar = curvedScalar1;
              rightScalar = curvedScalar3;
            } else {
              leftPosition = vertex1Position;
              rightPosition =vertex4Position;
              leftScalar = curvedScalar1;
              rightScalar = curvedScalar4;
            }
          } else if (vertexType < 0.45) {
            // Vertex extra 2
            if (above2 != above3) {
              leftPosition = vertex2Position;
              rightPosition =vertex3Position;
              leftScalar = curvedScalar2;
              rightScalar = curvedScalar3;
            } else {
              leftPosition = vertex2Position;
              rightPosition =vertex4Position;
              leftScalar = curvedScalar2;
              rightScalar = curvedScalar4;
            }
          } else {
            // Vertex extra 3
            if (above3 != above4) {
              leftPosition = vertex3Position;
              rightPosition =vertex4Position;
              leftScalar = curvedScalar3;
              rightScalar = curvedScalar4;
            } else {
              leftPosition = vertex2Position;
              rightPosition =vertex4Position;
              leftScalar = curvedScalar2;
              rightScalar = curvedScalar4;
            }
          }
        } else {
          // Case with one triangle. Skip for second triangle.
          if (vertexType > 0.25) continue;

          if (vertexType < 0.05) {
            // Vertex 1
            if (above1 != above2) {
              leftPosition = vertex1Position;
              rightPosition =vertex2Position;
              leftScalar = curvedScalar1;
              rightScalar = curvedScalar2;
            } else if (above1 != above3) {
              leftPosition = vertex1Position;
              rightPosition =vertex3Position;
              leftScalar = curvedScalar1;
              rightScalar = curvedScalar3;
            } else {
              leftPosition = vertex1Position;
              rightPosition =vertex4Position;
              leftScalar = curvedScalar1;
              rightScalar = curvedScalar4;
            }
          } else if (vertexType < 0.15) {
            // Vertex 2
            if (above2 != above3) {
              leftPosition = vertex2Position;
              rightPosition =vertex3Position;
              leftScalar = curvedScalar2;
              rightScalar = curvedScalar3;
            } else if (above2 != above4) {
              leftPosition = vertex2Position;
              rightPosition =vertex4Position;
              leftScalar = curvedScalar2;
              rightScalar = curvedScalar4;
            } else {
              leftPosition = vertex1Position;
              rightPosition =vertex3Position;
              leftScalar = curvedScalar1;
              rightScalar = curvedScalar3;
            }
          } else {
            // Vertex 3
            if (above3 != above4) {
              leftPosition = vertex3Position;
              rightPosition =vertex4Position;
              leftScalar = curvedScalar3;
              rightScalar = curvedScalar4;
            } else if (above2 != above4) {
              leftPosition = vertex2Position;
              rightPosition =vertex4Position;
              leftScalar = curvedScalar2;
              rightScalar = curvedScalar4;
            } else {
              leftPosition = vertex1Position;
              rightPosition =vertex4Position;
              leftScalar = curvedScalar1;
              rightScalar = curvedScalar4;
            }
          }
        }

        // Make sure the lower value is on the left.
        if (leftScalar > rightScalar) {
          float tempScalar = leftScalar;
          vec3 tempPosition = leftPosition;
          leftScalar = rightScalar;
          leftPosition = rightPosition;
          rightScalar = tempScalar;
          rightPosition = tempPosition;
        }

        float range = rightScalar - leftScalar;
        float p = (isovalue - leftScalar) / range;
        vec3 vertexPosition = mix(leftPosition, rightPosition, p);
        scalar = mix(leftScalar, rightScalar, p);

        gl_Position = projectionMatrix * modelViewMatrix * vec4(vertexPosition, 1.0);
        return;
      }
    }
  }

  gl_Position = vec4(0,0,0,1);
  scalar = -1.0;
}
"""

      fragmentShader: """
precision highp float;
precision highp int;

uniform sampler2D gradientTexture;

uniform float time;
uniform vec3 color;
uniform float opacity;

varying float scalar;

void main()	{
  if (scalar >= 0.0) {
    gl_FragColor = vec4(texture2D(gradientTexture, vec2(scalar, 0)).rgb, opacity);
  } else {
    gl_FragColor = vec4(color, opacity);
  }
}
"""
