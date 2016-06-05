// Generated by CoffeeScript 1.10.0
(function() {
  'use strict';
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  TopViewer.Model = (function(superClass) {
    extend(Model, superClass);

    function Model(options) {
      var height, i, j, k, l, ref;
      this.options = options;
      Model.__super__.constructor.apply(this, arguments);
      this.matrixAutoUpdate = false;
      this.nodes = this.options.nodes;
      this.meshes = {};
      this.scalars = {};
      this.vectors = {};
      this.frames = [
        {
          frameTime: -1
        }
      ];
      this.boundingBox = new THREE.Box3;
      height = 1;
      while (this.nodes.length / 3 > 4096 * height) {
        height *= 2;
      }
      this.basePositions = new Float32Array(4096 * height * 3);
      for (i = k = 0, ref = this.nodes.length / 3; 0 <= ref ? k < ref : k > ref; i = 0 <= ref ? ++k : --k) {
        for (j = l = 0; l <= 2; j = ++l) {
          this.basePositions[i * 3 + j] = this.nodes[i * 3 + j];
        }
        this.boundingBox.expandByPoint(new THREE.Vector3(this.nodes[i * 3], this.nodes[i * 3 + 1], this.nodes[i * 3 + 2]));
      }
      this.boundingSphere = this.boundingBox.getBoundingSphere();
      this.basePositionsTexture = new THREE.DataTexture(this.basePositions, 4096, height, THREE.RGBFormat, THREE.FloatType);
      this.basePositionsTexture.needsUpdate = true;
      this.scalarsTexture = new THREE.DataTexture(new Float32Array(4096 * 4096 * 3), 4096, 4096, THREE.AlphaFormat, THREE.FloatType);
      this.scalarsTexture.needsUpdate = true;
      this.displacementsTexture = new THREE.DataTexture(new Float32Array(4096 * 4096 * 3), 4096, 4096, THREE.RGBFormat, THREE.FloatType);
      this.displacementsTexture.needsUpdate = true;
      this.material = new TopViewer.ModelMaterial(this);
      this.wireframeMaterial = new TopViewer.ModelMaterial(this);
      this.wireframeMaterial.uniforms.opacity.value = 0.3;
      this.wireframeMaterial.transparent = true;
      this.isolineMaterial = new TopViewer.IsolineMaterial(this);
      this.isolineMaterial.uniforms.opacity.value = 0.9;
      this.isolineMaterial.transparent = true;
      this.displacementVector = null;
      this.colorScalar = null;
      if (this.nodes.length) {
        this.options.engine.scene.addModel(this);
      }
      this._updateFrames();
      this._currentVectorFrames = {};
    }

    Model.prototype.addElements = function(elementsName, elementsInstance) {
      return this.meshes[elementsName] = new TopViewer.Mesh({
        name: elementsName,
        elements: elementsInstance.elements,
        model: this,
        engine: this.options.engine
      });
    };

    Model.prototype.addScalar = function(scalarName, scalar) {
      var array, frame, height, i, k, l, len, ref, ref1;
      this.scalars[scalarName] = scalar;
      this._updateFrames();
      ref = scalar.frames;
      for (k = 0, len = ref.length; k < len; k++) {
        frame = ref[k];
        height = 1;
        while (frame.scalars.length > 4096 * height) {
          height *= 2;
        }
        array = new Float32Array(4096 * height);
        for (i = l = 0, ref1 = frame.scalars.length; 0 <= ref1 ? l < ref1 : l > ref1; i = 0 <= ref1 ? ++l : --l) {
          array[i] = frame.scalars[i];
        }
        frame.texture = new THREE.DataTexture(array, 4096, height, THREE.AlphaFormat, THREE.FloatType);
        frame.texture.needsUpdate = true;
      }
      return this.colorScalar != null ? this.colorScalar : this.colorScalar = scalar;
    };

    Model.prototype.addVector = function(vectorName, vector) {
      var array, frame, height, i, k, l, len, ref, ref1;
      this.vectors[vectorName] = vector;
      this._updateFrames();
      ref = vector.frames;
      for (k = 0, len = ref.length; k < len; k++) {
        frame = ref[k];
        height = 1;
        while (frame.vectors.length / 3 > 4096 * height) {
          height *= 2;
        }
        array = new Float32Array(4096 * height * 3);
        for (i = l = 0, ref1 = frame.vectors.length; 0 <= ref1 ? l < ref1 : l > ref1; i = 0 <= ref1 ? ++l : --l) {
          array[i] = frame.vectors[i];
        }
        frame.texture = new THREE.DataTexture(array, 4096, height, THREE.RGBFormat, THREE.FloatType);
        frame.texture.needsUpdate = true;
      }
      this.options.engine.renderingControls.addVector(vectorName, vector);
      return this.displacementVector != null ? this.displacementVector : this.displacementVector = vector;
    };

    Model.prototype._updateFrames = function() {
      var frame, frameTime, frameTimes, i, k, l, len, len1, len2, len3, m, n, newFrame, o, ref, ref1, ref2, ref3, ref4, ref5, ref6, ref7, results, scalar, scalarFrame, scalarName, vector, vectorFrame, vectorName;
      frameTimes = [];
      ref = this.scalars;
      for (scalarName in ref) {
        scalar = ref[scalarName];
        ref1 = scalar.frames;
        for (k = 0, len = ref1.length; k < len; k++) {
          frame = ref1[k];
          frameTimes = _.union(frameTimes, [parseFloat(frame.time)]);
        }
      }
      ref2 = this.vectors;
      for (vectorName in ref2) {
        vector = ref2[vectorName];
        ref3 = vector.frames;
        for (l = 0, len1 = ref3.length; l < len1; l++) {
          frame = ref3[l];
          frameTimes = _.union(frameTimes, [parseFloat(frame.time)]);
        }
      }
      frameTimes.sort(function(a, b) {
        return a - b;
      });
      this.options.engine.animation.addFrameTimes(frameTimes);
      if (!frameTimes.length) {
        frameTimes.push(-1);
      }
      this.frames = [];
      results = [];
      for (m = 0, len2 = frameTimes.length; m < len2; m++) {
        frameTime = frameTimes[m];
        newFrame = {
          time: frameTime,
          scalars: [],
          vectors: []
        };
        ref4 = this.scalars;
        for (scalarName in ref4) {
          scalar = ref4[scalarName];
          for (i = n = 0, ref5 = scalar.frames.length; 0 <= ref5 ? n < ref5 : n > ref5; i = 0 <= ref5 ? ++n : --n) {
            scalarFrame = scalar.frames[i];
            if (frameTime !== scalarFrame.time) {
              continue;
            }
            newFrame.scalars.push({
              scalarName: scalarName,
              scalarFrame: scalarFrame
            });
          }
        }
        ref6 = this.vectors;
        for (vectorName in ref6) {
          vector = ref6[vectorName];
          ref7 = vector.frames;
          for (o = 0, len3 = ref7.length; o < len3; o++) {
            vectorFrame = ref7[o];
            if (frameTime !== vectorFrame.time) {
              continue;
            }
            newFrame.vectors.push({
              vectorName: vectorName,
              vectorFrame: vectorFrame
            });
          }
        }
        results.push(this.frames.push(newFrame));
      }
      return results;
    };

    Model.prototype.showFrame = function(frameTime) {
      var frame, frameIndex, k, l, len, len1, m, mesh, meshName, ref, ref1, ref2, ref3, renderingControls, results, scalar, scalarData, testFrame, time, vector;
      frame = null;
      for (frameIndex = k = 0, ref = this.frames.length; 0 <= ref ? k < ref : k > ref; frameIndex = 0 <= ref ? ++k : --k) {
        testFrame = this.frames[frameIndex];
        time = testFrame.time;
        if (time === frameTime || time === -1) {
          frame = testFrame;
        }
      }
      this.visible = frame && this.nodes.length;
      if (!this.visible) {
        return;
      }
      renderingControls = this.options.engine.renderingControls;
      ref1 = frame.scalars;
      for (l = 0, len = ref1.length; l < len; l++) {
        scalar = ref1[l];
        scalarData = this.scalars[scalar.scalarName];
        if (scalarData === this.colorScalar) {
          this.material.uniforms.scalarsTexture.value = scalar.scalarFrame.texture;
          this.material.uniforms.scalarsMin.value = scalarData.limits.minValue;
          this.material.uniforms.scalarsRange.value = scalarData.limits.maxValue - scalarData.limits.minValue;
          this.isolineMaterial.uniforms.scalarsTexture.value = scalar.scalarFrame.texture;
          this.isolineMaterial.uniforms.scalarsMin.value = scalarData.limits.minValue;
          this.isolineMaterial.uniforms.scalarsRange.value = scalarData.limits.maxValue - scalarData.limits.minValue;
        }
      }
      ref2 = frame.vectors;
      for (m = 0, len1 = ref2.length; m < len1; m++) {
        vector = ref2[m];
        if (this.vectors[vector.vectorName] === this.displacementVector) {
          this.material.uniforms.displacementFactor.value = renderingControls.displacementFactor.value;
          this.material.uniforms.displacementsTexture.value = vector.vectorFrame.texture;
          this.wireframeMaterial.uniforms.displacementFactor.value = renderingControls.displacementFactor.value;
          this.wireframeMaterial.uniforms.displacementsTexture.value = vector.vectorFrame.texture;
          this.isolineMaterial.uniforms.displacementFactor.value = renderingControls.displacementFactor.value;
          this.isolineMaterial.uniforms.displacementsTexture.value = vector.vectorFrame.texture;
        }
      }
      time = performance.now() / 1000;
      this.material.uniforms.time.value = time;
      this.wireframeMaterial.uniforms.time.value = time;
      this.isolineMaterial.uniforms.time.value = time;
      ref3 = this.meshes;
      results = [];
      for (meshName in ref3) {
        mesh = ref3[meshName];
        results.push(mesh.showFrame());
      }
      return results;
    };

    return Model;

  })(THREE.Object3D);

}).call(this);

//# sourceMappingURL=model.js.map