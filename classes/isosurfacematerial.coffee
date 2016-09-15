'use strict'

class TopViewer.IsosurfaceMaterial extends TopViewer.IsovalueMaterial
  constructor: (@model) ->
    options =
      uniforms:
        lightingBidirectional:
          value: 0

      defines:
        USE_SHADOWMAP: ''

      side: THREE.DoubleSide
      lights: true

      vertexShader: """
#{TopViewer.ShaderChunks.commonVertex}
#{TopViewer.ShaderChunks.positionsMaterialVertex}
#{TopViewer.ShaderChunks.vertexMaterialVertex}
#{TopViewer.ShaderChunks.isovalueMaterialVertex}
#{TopViewer.ShaderChunks.surfaceMaterialVertex}

attribute vec2 vertexIndexCorner1;
attribute vec2 vertexIndexCorner2;
attribute vec2 vertexIndexCorner3;
attribute vec2 vertexIndexCorner4;
attribute float cornerIndex;

const int isosurfaceCount = 3;

#{THREE.ShaderChunk.shadowmap_pars_vertex}

void main()	{
  /*
    Isosurfaces vertex shader creates a surface inside the tetrahedron volume if the target
    scalar value is found inside the tetrahedron. We know this is the case if some of the scalar values on the 4
    vertices are below and some are above the target scalar value. We then construct the isosurface inside this
    tetrahedron by dynamically constructing one or two triangles that span between points on the tetrahedron sides at
    which we estimate (with linear interpolation) that the isovalue is found.

    Becuase these one or two triangles need to be dynamically generated, we reserves 6 vertices in the vertex buffer as
    potential isosurface triangle corners. Each of these 6 corners need information about the 4 tetrahedron vertices so
    we supply this using the 4 vertex indices (these are texture coordinates to the point inside the data textures where
    data for that index is found). We then distinguish between each of the 6 corners with the cornerIndex attribute,
    which can have values of 0.0, 0.1, 0.2, 0.3, 0.4 and 0.5 to indicate the corner.

    We first construct the whole isosurface triangle (we need all three corners so we can calculate the isosurface
    normal … but feel free to try a better version, perhaps by calculating the gradient directly from tetrahedron
    vertex scalar values) and then pass on one of the corners as the result of the shader, based on the corner index.

    If the isosurface triangle is not needed, it is discarded by degenerating its vertices into a single point.
  */
  scalar = -1.0;

  // Isosurfaces only exists if we have a scalar.
  if (scalarsRange > 0.0) {
    #{TopViewer.ShaderChunks.isovalueMaterialVertexSetup 4}

    #{TopViewer.ShaderChunks.isovalueMaterialIsovalueIteration 4}
      if (aboveCount==0 || aboveCount==4) {
        // None of the triangles need to show.
        continue;
      } else if (aboveCount != 2 && cornerIndex > 0.25) {
        // The second triangle doesn't need to show.
        continue;
      } else {
        // Calculate positions and scalar values on the corners of the isosurface.
        vec3 cornerLeftPositions[3], cornerRightPositions[3];
        float cornerLeftCurvedScalars[3], cornerRightCurvedScalars[3];
        float cornerLeftVertexColorScalars[3], cornerRightVertexColorScalars[3];

        // Determine which of the cases we have. There are 4 vertices so we have 16 (2^4) possible combinations of
        // vertices being above or below the isovalue. Each case then constructs triangles between corners that will
        // lie somewhere on the line between one vertex that is above and one that is below. The left-right combination
        // stores which vertices these are. They are carefuly selected so that all triangles face into the same
        // direction of the gradient.
        int case = 0;
        if (above[3]) case += 1;
        if (above[2]) case += 2;
        if (above[1]) case += 4;
        if (above[0]) case += 8;

        if (case==1) {
          #{@_setupCase [0,1,2], [3,3,3]}
        } else if (case==2) {
          #{@_setupCase [0,3,1], [2,2,2]}
        } else if (case==3) {
          if (cornerIndex < 0.25) {
            #{@_setupCase [0,0,1], [2,3,3]}
          } else {
            #{@_setupCase [1,0,1], [2,2,3]}
          }

        } else if (case==4) {
          #{@_setupCase [0,2,3], [1,1,1]}
        } else if (case==5) {
          if (cornerIndex < 0.25) {
            #{@_setupCase [0,1,0], [1,2,3]}
          } else {
            #{@_setupCase [0,1,2], [3,2,3]}
          }
        } else if (case==6) {
          if (cornerIndex < 0.25) {
            #{@_setupCase [0,1,0], [2,3,1]}
          } else {
            #{@_setupCase [2,1,0], [3,3,2]}
          }
        } else if (case==7) {
          #{@_setupCase [1,2,3], [0,0,0]}
        } else if (case==8) {
          #{@_setupCase [1,3,2], [0,0,0]}
        } else if (case==9) {
          if (cornerIndex < 0.25) {
            #{@_setupCase [0,1,0], [1,3,2]}
          } else {
            #{@_setupCase [1,2,0], [3,3,2]}
          }
        } else if (case==10) {
          if (cornerIndex < 0.25) {
            #{@_setupCase [0,1,0], [3,2,1]}
          } else {
            #{@_setupCase [2,1,0], [3,2,3]}
          }
        } else if (case==11) {
          #{@_setupCase [0,3,2], [1,1,1]}
        } else if (case==12) {
          if (cornerIndex < 0.25) {
            #{@_setupCase [0,1,0], [2,3,3]}
          } else {
            #{@_setupCase [0,1,1], [2,2,3]}
          }
        } else if (case==13) {
          #{@_setupCase [0,1,3], [2,2,2]}
        } else if (case==14) {
          #{@_setupCase [0,2,1], [3,3,3]}
        } else {
          continue;
        }

        // Calculate all corner positions and scalar values. We do this by linearly interpolating between the positions
        // and scalar values at the two vertices we determine in the previous step.
        vec3 cornerPositions[3];
        float cornerScalars[3];

        for (int i=0; i<3; i++) {
          float range = cornerLeftCurvedScalars[i] - cornerRightCurvedScalars[i];
          float percentage = (cornerLeftCurvedScalars[i] - isovalue) / range;

          cornerPositions[i] = mix(cornerLeftPositions[i], cornerRightPositions[i], percentage);
          cornerScalars[i] = mix(cornerLeftVertexColorScalars[i], cornerRightVertexColorScalars[i], percentage);
        }

        vec3 tangent1, tangent2;

        tangent1 = cornerPositions[0] - cornerPositions[1];
        tangent2 = cornerPositions[2] - cornerPositions[0];

        vec3 normal = normalize(cross(tangent1, tangent2));
        normalEye = normalize((modelViewMatrix * vec4(normal, 0.0)).xyz);

        // Determine which corner we're currently on.
        vec3 cornerPosition;

        if (cornerIndex < 0.05) {cornerPosition = cornerPositions[0]; scalar = cornerScalars[0];}
        else if (cornerIndex < 0.15) {cornerPosition = cornerPositions[1]; scalar = cornerScalars[1];}
        else if (cornerIndex < 0.25) {cornerPosition = cornerPositions[2]; scalar = cornerScalars[2];}
        else if (cornerIndex < 0.35) {cornerPosition = cornerPositions[0]; scalar = cornerScalars[0];}
        else if (cornerIndex < 0.45) {cornerPosition = cornerPositions[1]; scalar = cornerScalars[1];}
        else {cornerPosition = cornerPositions[2]; scalar = cornerScalars[2];}

        gl_Position = projectionMatrix * modelViewMatrix * vec4(cornerPosition, 1.0);
        return;
      }
    }
  }

  gl_Position = vec4(0,0,0,1);
  scalar = -1.0;
}
"""

      fragmentShader: TopViewer.Shaders.surfaceFragmentShader

    _.extend options.uniforms, THREE.UniformsLib.lights

    super @model, options

  _setupCase: (left, right) ->
    """
          cornerLeftPositions[0] = vertexPositions[#{left[0]}]; cornerRightPositions[0] = vertexPositions[#{right[0]}];
          cornerLeftPositions[1] = vertexPositions[#{left[1]}]; cornerRightPositions[1] = vertexPositions[#{right[1]}];
          cornerLeftPositions[2] = vertexPositions[#{left[2]}]; cornerRightPositions[2] = vertexPositions[#{right[2]}];

          cornerLeftCurvedScalars[0] = curvedScalars[#{left[0]}]; cornerRightCurvedScalars[0] = curvedScalars[#{right[0]}];
          cornerLeftCurvedScalars[1] = curvedScalars[#{left[1]}]; cornerRightCurvedScalars[1] = curvedScalars[#{right[1]}];
          cornerLeftCurvedScalars[2] = curvedScalars[#{left[2]}]; cornerRightCurvedScalars[2] = curvedScalars[#{right[2]}];

          cornerLeftVertexColorScalars[0] = vertexColorScalars[#{left[0]}]; cornerRightVertexColorScalars[0] = vertexColorScalars[#{right[0]}];
          cornerLeftVertexColorScalars[1] = vertexColorScalars[#{left[1]}]; cornerRightVertexColorScalars[1] = vertexColorScalars[#{right[1]}];
          cornerLeftVertexColorScalars[2] = vertexColorScalars[#{left[2]}]; cornerRightVertexColorScalars[2] = vertexColorScalars[#{right[2]}];
"""
