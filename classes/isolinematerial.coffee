'use strict'

class TopViewer.IsolineMaterial extends TopViewer.IsovalueMaterial
  constructor: (@model) ->
    super @model,
      linewidth: 3

      vertexShader: """
#{TopViewer.ShaderChunks.commonVertex}
#{TopViewer.ShaderChunks.positionsMaterialVertex}
#{TopViewer.ShaderChunks.vertexMaterialVertex}
#{TopViewer.ShaderChunks.isovalueMaterialVertex}

attribute vec2 vertexIndexCorner1;
attribute vec2 vertexIndexCorner2;
attribute vec2 vertexIndexCorner3;
attribute float cornerIndex;

const int isosurfaceCount = 1;

void main()	{
  if (scalarsRange > 0.0) {
    #{TopViewer.ShaderChunks.isovalueMaterialVertexSetup 3}

    #{TopViewer.ShaderChunks.isovalueMaterialIsovalueIteration 3}
      if (aboveCount==0 || aboveCount==3) {
        // The isoline doesn't need to show.
        continue;
      } else {
        vec3 leftPosition;
        vec3 rightPosition;
        float leftScalar;
        float rightScalar;
        float leftVertexColorScalar;
        float rightVertexColorScalar;

        if (cornerIndex < 0.5) {
          // Start vertex
          if (above[0] != above[1]) {
            leftPosition = vertexPositions[0];
            rightPosition =vertexPositions[1];
            leftScalar = curvedScalars[0];
            rightScalar = curvedScalars[1];
            leftVertexColorScalar = vertexColorScalars[0];
            rightVertexColorScalar = vertexColorScalars[1];
          } else {
            leftPosition = vertexPositions[1];
            rightPosition =vertexPositions[2];
            leftScalar = curvedScalars[1];
            rightScalar = curvedScalars[2];
            leftVertexColorScalar = vertexColorScalars[1];
            rightVertexColorScalar = vertexColorScalars[2];
          }
        } else {
          // End vertex
          if (above[0] != above[2]) {
            leftPosition = vertexPositions[0];
            rightPosition =vertexPositions[2];
            leftScalar = curvedScalars[0];
            rightScalar = curvedScalars[2];
            leftVertexColorScalar = vertexColorScalars[0];
            rightVertexColorScalar = vertexColorScalars[2];
          } else {
            leftPosition = vertexPositions[1];
            rightPosition =vertexPositions[2];
            leftScalar = curvedScalars[1];
            rightScalar = curvedScalars[2];
            leftVertexColorScalar = vertexColorScalars[1];
            rightVertexColorScalar = vertexColorScalars[2];
          }
        }

        float range = rightScalar - leftScalar;
        float percentage = (isovalue - leftScalar) / range;

        // Interpolate vertex position.
        vec3 vertexPosition = mix(leftPosition, rightPosition, percentage);
        gl_Position = projectionMatrix * modelViewMatrix * vec4(vertexPosition, 1.0);

        // Interpolate vertex color scalar value.
        scalar = mix(leftVertexColorScalar, rightVertexColorScalar, percentage);

        return;
      }
    }
  }

  gl_Position = vec4(0,0,0,1);
  scalar = -1.0;
}
"""

      fragmentShader: TopViewer.Shaders.wireframeFragmentShader
