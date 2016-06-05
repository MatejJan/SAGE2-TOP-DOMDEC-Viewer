// Generated by CoffeeScript 1.10.0
(function() {
  'use strict';
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  TopViewer.Scene = (function(superClass) {
    extend(Scene, superClass);

    function Scene(options) {
      Scene.__super__.constructor.call(this);
      this.engine = options.engine;
      this.skyLight = new THREE.HemisphereLight(0x92b6ee, 0x333333, 0.8);
      this.add(this.skyLight);
      this.whiteLight = new THREE.AmbientLight(0xffffff);
      this.add(this.whiteLight);
      this.directionalLight = this.addShadowedLight(0.2, 1, 0.3, 0xeadbad, 1);
      this.planeMaterial = new THREE.MeshBasicMaterial({
        color: 0x444550
      });
      this.modelMaterial = new THREE.MeshLambertMaterial({
        color: 0xffffff,
        vertexColors: THREE.VertexColors,
        side: THREE.DoubleSide,
        combine: THREE.MultiplyOperation,
        reflectivity: 0.3
      });
      this.wireframeMaterial = new THREE.MeshBasicMaterial({
        color: 0xffffff,
        opacity: 0.5,
        transparent: true,
        side: THREE.DoubleSide,
        wireframe: true
      });
      this.plane = new THREE.PlaneGeometry(20, 20);
      this.floor = new THREE.Mesh(this.plane, this.planeMaterial);
      this.floor.rotation.x = -Math.PI * 0.5;
      this.floor.rotation.z = -Math.PI * 0.5;
      this.floor.receiveShadow = true;
      this.add(this.floor);
      this.normalizationMatrix = new THREE.Matrix4();
      this.rotationMatrix = new THREE.Matrix4();
      this.scaleMatrix = new THREE.Matrix4();
      this.translationMatrix = new THREE.Matrix4();
      this._currentFrameSet = [];
      this.sceneBoundingBox = new THREE.Box3(new THREE.Vector3(), new THREE.Vector3());
    }

    Scene.prototype.destroy = function() {
      this.remove.apply(this, this.children);
      this.modelMaterial.dispose();
      return this.planeMaterial.dispose();
    };

    Scene.prototype.addShadowedLight = function(x, y, z, color, intensity) {
      var d, directionalLight;
      directionalLight = new THREE.DirectionalLight(color, intensity);
      directionalLight.position.set(x, y, z);
      this.add(directionalLight);
      directionalLight.castShadow = true;
      d = 3;
      directionalLight.shadowCameraLeft = -d;
      directionalLight.shadowCameraRight = d;
      directionalLight.shadowCameraTop = d;
      directionalLight.shadowCameraBottom = -d;
      directionalLight.shadowCameraNear = 0.0005;
      directionalLight.shadowCameraFar = 50;
      directionalLight.shadowMapWidth = 1024;
      directionalLight.shadowMapHeight = 1024;
      directionalLight.shadowDarkness = 0.8;
      return directionalLight;
    };

    Scene.prototype.showFrameSet = function(frameSet) {
      var frame, i, j, k, l, len, len1, len2, len3, ref, ref1, ref2, wireframe;
      if (frameSet == null) {
        frameSet = [];
      }
      ref = this._currentFrameSet;
      for (i = 0, len = ref.length; i < len; i++) {
        frame = ref[i];
        frame.mesh.visible = false;
      }
      for (j = 0, len1 = frameSet.length; j < len1; j++) {
        frame = frameSet[j];
        frame.mesh.visible = true;
      }
      wireframe = this.engine.renderingControls.wireframeControl.value;
      if (wireframe) {
        ref1 = this._currentFrameSet;
        for (k = 0, len2 = ref1.length; k < len2; k++) {
          frame = ref1[k];
          if ((ref2 = frame.wireframeMesh) != null) {
            ref2.visible = false;
          }
        }
        for (l = 0, len3 = frameSet.length; l < len3; l++) {
          frame = frameSet[l];
          this.generateWireframeMesh(frame);
          frame.wireframeMesh.visible = true;
        }
      }
      this._currentFrameSet = frameSet;
      return this.update();
    };

    Scene.prototype.accommodateMeshBounds = function(mesh) {
      this.sceneBoundingBox = this.sceneBoundingBox.union(mesh.geometry.boundingBox);
      this.updateScale();
      return this.updateTranslation();
    };

    Scene.prototype.addModel = function(model) {
      model.matrix = this.normalizationMatrix;
      this.add(model);
      return this.update();
    };

    Scene.prototype.addMesh = function(mesh) {
      return this.update();
    };

    Scene.prototype.update = function() {
      var i, j, len, len1, materialNeedsUpdate, mesh, model, ref, ref1;
      ref = this.children;
      for (i = 0, len = ref.length; i < len; i++) {
        model = ref[i];
        if (model instanceof TopViewer.Model) {
          ref1 = model.meshes;
          for (j = 0, len1 = ref1.length; j < len1; j++) {
            mesh = ref1[j];
            mesh.castShadow = this.engine.shadows;
          }
        }
      }
      this.directionalLight.visible = this.engine.directionalLight;
      this.whiteLight.visible = !this.engine.ambientLight;
      this.skyLight.visible = this.engine.ambientLight;
      materialNeedsUpdate = false;
      if (this.engine.vertexColors !== this._vertexColor) {
        this.modelMaterial.vertexColors = this.engine.vertexColors ? THREE.VertexColors : THREE.NoColors;
        this._vertexColor = this.engine.vertexColors;
        materialNeedsUpdate = true;
      }
      if (materialNeedsUpdate) {
        return this.modelMaterial.needsUpdate = true;
      }
    };

    Scene.prototype.updateScale = function() {
      var relativeChange, scaleFactor, sceneBoundingBoxDiagonal;
      sceneBoundingBoxDiagonal = new THREE.Vector3().subVectors(this.sceneBoundingBox.max, this.sceneBoundingBox.min);
      scaleFactor = 2 / sceneBoundingBoxDiagonal.length();
      if (this._scaleFactor) {
        relativeChange = this._scaleFactor / scaleFactor;
        if (relativeChange < 1.5) {
          return;
        }
      }
      this._scaleFactor = scaleFactor;
      this.scaleMatrix.makeScale(scaleFactor, scaleFactor, scaleFactor);
      this._recomputeNormalizationMatrix();
      return this._updateFloor();
    };

    Scene.prototype.updateRotation = function() {
      this.rotationMatrix.copy(this.engine.objectRotation);
      return this._recomputeNormalizationMatrix();
    };

    Scene.prototype.updateTranslation = function() {
      var center, relativeChange;
      center = this.sceneBoundingBox.center().clone();
      if (this._centerDistance) {
        relativeChange = this._centerDistance / center.length();
        if ((0.5 < relativeChange && relativeChange < 1.5)) {
          return;
        }
      }
      this._centerDistance = center.length();
      center.negate();
      this.translationMatrix.makeTranslation(center.x, center.y, center.z);
      this._recomputeNormalizationMatrix();
      return this._updateFloor();
    };

    Scene.prototype._updateFloor = function() {
      var center, minY;
      center = this.sceneBoundingBox.center().clone();
      center.negate();
      minY = (this.sceneBoundingBox.min.y + center.y) * this._scaleFactor;
      return this.floor.position.y = minY;
    };

    Scene.prototype._recomputeNormalizationMatrix = function() {
      this.normalizationMatrix.copy(this.rotationMatrix);
      this.normalizationMatrix.multiply(this.scaleMatrix);
      return this.normalizationMatrix.multiply(this.translationMatrix);
    };

    return Scene;

  })(THREE.Scene);

}).call(this);

//# sourceMappingURL=scene.js.map