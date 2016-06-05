// Generated by CoffeeScript 1.10.0
(function() {
  'use strict';
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  TopViewer.IsolineMaterial = (function(superClass) {
    extend(IsolineMaterial, superClass);

    function IsolineMaterial(model) {
      this.model = model;
      IsolineMaterial.__super__.constructor.call(this, {
        uniforms: {
          basePositionsTexture: {
            type: 't',
            value: this.model.basePositionsTexture
          },
          displacementsTexture: {
            type: 't',
            value: this.model.displacementsTexture
          },
          displacementFactor: {
            type: 'f',
            value: 0
          },
          scalarsTexture: {
            type: 't',
            value: this.model.scalarsTexture
          },
          scalarsMin: {
            type: 'f',
            value: 0
          },
          scalarsRange: {
            type: 'f',
            value: 0
          },
          gradientTexture: {
            type: 't',
            value: this.model.options.engine.gradientTexture
          },
          gradientCurveTexture: {
            type: 't',
            value: this.model.options.engine.gradientCurveTexture
          },
          time: {
            type: 'f',
            value: 0
          },
          color: {
            type: 'c',
            value: new THREE.Color('white')
          },
          opacity: {
            type: 'f',
            value: 1
          }
        },
        side: THREE.DoubleSide,
        linewidth: 3,
        vertexShader: "precision highp float;\nprecision highp int;\n\nuniform mat4 modelViewMatrix;\nuniform mat4 projectionMatrix;\n\nuniform sampler2D basePositionsTexture;\n\nuniform sampler2D displacementsTexture;\nuniform float displacementFactor;\n\nuniform sampler2D scalarsTexture;\nuniform float scalarsMin;\nuniform float scalarsRange;\n\nuniform sampler2D gradientCurveTexture;\n\nuniform float time;\n\nattribute vec2 vertex1Index;\nattribute vec2 vertex2Index;\nattribute vec2 vertex3Index;\nattribute float vertexType;\n\nvarying float scalar;\n\nconst float isostep = 0.1;\n\nvoid main()	{\n  if (scalarsRange > 0.0) {\n    vec3 vertex1Position = texture2D(basePositionsTexture, vertex1Index).xyz;\n    vec3 vertex2Position = texture2D(basePositionsTexture, vertex2Index).xyz;\n    vec3 vertex3Position = texture2D(basePositionsTexture, vertex3Index).xyz;\n\n    if (displacementFactor > 0.0) {\n      vertex1Position += texture2D(displacementsTexture, vertex1Index).xyz * displacementFactor;\n      vertex2Position += texture2D(displacementsTexture, vertex2Index).xyz * displacementFactor;\n      vertex3Position += texture2D(displacementsTexture, vertex3Index).xyz * displacementFactor;\n    }\n\n    if (vertexType == 0.0) {\n      gl_Position = projectionMatrix * modelViewMatrix * vec4(vertex1Position, 1.0);\n    } else {\n      gl_Position = projectionMatrix * modelViewMatrix * vec4(vertex2Position, 1.0);\n    }\n\n    float scalar1 = clamp((texture2D(scalarsTexture, vertex1Index).a - scalarsMin) / scalarsRange, 0.01, 0.99);\n    float scalar2 = clamp((texture2D(scalarsTexture, vertex2Index).a - scalarsMin) / scalarsRange, 0.01, 0.99);\n    float scalar3 = clamp((texture2D(scalarsTexture, vertex3Index).a - scalarsMin) / scalarsRange, 0.01, 0.99);\n    float curvedScalar1 = texture2D(gradientCurveTexture, vec2(scalar1, 0)).a;\n    float curvedScalar2 = texture2D(gradientCurveTexture, vec2(scalar2, 0)).a;\n    float curvedScalar3 = texture2D(gradientCurveTexture, vec2(scalar3, 0)).a;\n\n    for (float isovalue=0.0;isovalue<1.0;isovalue+=isostep) {\n      bool above1 = curvedScalar1 > isovalue;\n      bool above2 = curvedScalar2 > isovalue;\n      bool above3 = curvedScalar3 > isovalue;\n\n      if (above1 == above2 && above1 == above3) {\n        continue;\n      } else {\n        vec3 leftPosition;\n        vec3 rightPosition;\n        float leftScalar;\n        float rightScalar;\n\n        if (vertexType == 0.0) {\n          // Start vertex\n          if (above1 != above2) {\n            leftPosition = vertex1Position;\n            rightPosition =vertex2Position;\n            leftScalar = curvedScalar1;\n            rightScalar = curvedScalar2;\n          } else {\n            leftPosition = vertex2Position;\n            rightPosition =vertex3Position;\n            leftScalar = curvedScalar2;\n            rightScalar = curvedScalar3;\n          }\n        } else {\n          // End vertex\n          if (above1 != above3) {\n            leftPosition = vertex1Position;\n            rightPosition =vertex3Position;\n            leftScalar = curvedScalar1;\n            rightScalar = curvedScalar3;\n          } else {\n            leftPosition = vertex2Position;\n            rightPosition =vertex3Position;\n            leftScalar = curvedScalar2;\n            rightScalar = curvedScalar3;\n          }\n        }\n\n        // Make sure the lower value is on the left.\n        if (leftScalar > rightScalar) {\n          float tempScalar = leftScalar;\n          vec3 tempPosition = leftPosition;\n          leftScalar = rightScalar;\n          leftPosition = rightPosition;\n          rightScalar = tempScalar;\n          rightPosition = tempPosition;\n        }\n\n        float range = rightScalar - leftScalar;\n        float p = (isovalue - leftScalar) / range;\n        vec3 vertexPosition = mix(leftPosition, rightPosition, p);\n        //scalar = mix(leftScalar, rightScalar, p);\n        scalar = -1.0;\n\n        gl_Position = projectionMatrix * modelViewMatrix * vec4(vertexPosition, 1.0);\n        return;\n      }\n    }\n  }\n\n  gl_Position = vec4(0,0,0,1);\n  scalar = -1.0;\n}",
        fragmentShader: "precision highp float;\nprecision highp int;\n\nuniform sampler2D gradientTexture;\n\nuniform float time;\nuniform vec3 color;\nuniform float opacity;\n\nvarying float scalar;\n\nvoid main()	{\n  if (scalar >= 0.0) {\n    gl_FragColor = vec4(texture2D(gradientTexture, vec2(scalar, 0)).rgb, opacity);\n  } else {\n    gl_FragColor = vec4(color, opacity);\n  }\n}"
      });
    }

    return IsolineMaterial;

  })(THREE.RawShaderMaterial);

}).call(this);

//# sourceMappingURL=isolinematerial.js.map