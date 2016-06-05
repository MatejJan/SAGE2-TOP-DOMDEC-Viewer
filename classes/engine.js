// Generated by CoffeeScript 1.10.0
(function() {
  'use strict';
  TopViewer.Engine = (function() {
    function Engine(options) {
      var proxyCube;
      this.options = options;
      this.scene = new TopViewer.Scene({
        engine: this,
        resourcesPath: this.options.resourcesPath
      });
      this.camera = new THREE.PerspectiveCamera(45, this.options.width / this.options.height, 0.001, 100);
      this.camera.position.z = 3;
      this.renderer = new THREE.WebGLRenderer({
        antialias: true
      });
      this.renderer.setSize(window.innerWidth, window.innerHeight);
      this.renderer.setClearColor(0x444550);
      this.renderer.shadowMap.enabled = true;
      this.renderer.shadowMap.type = THREE.PCFSoftShadowMap;
      this.$appWindow = this.options.$appWindow;
      this.$appWindow.append(this.renderer.domElement);
      proxyCube = new THREE.Mesh(new THREE.BoxGeometry(1, 1, 1), new THREE.MeshLambertMaterial({
        color: 0xeeeeee
      }));
      this.cameraControls = new THREE.OrbitControls(this.camera, this.renderer.domElement);
      this.cameraControls.minDistance = 0.05;
      this.cameraControls.maxDistance = 10;
      this.cameraControls.zoomSpeed = 0.5;
      this.cameraControls.rotateSpeed = 2;
      this.cameraControls.autoRotate = false;
      this.cameraControls.autoRotateSpeed = 2.0;
      this.rotateControls = new THREE.OrbitControls(proxyCube, this.renderer.domElement);
      this.rotateControls.enableZoom = false;
      this.rotateControls.enablePan = false;
      this.rotateControls.minDistance = 0.05;
      this.rotateControls.maxDistance = 10;
      this.rotateControls.rotateSpeed = 1;
      this.rotateControls.autoRotate = false;
      this.rotateControls.autoRotateSpeed = 2.0;
      this.objectRotation = new THREE.Matrix4;
      this.activeControls = this.cameraControls;
      this.shadows = true;
      this.vertexColors = false;
      this.reflections = true;
      this.directionalLight = true;
      this.ambientLight = true;
      this.uiAreas = [];
      this.animation = new TopViewer.Animation;
      this.playbackControls = new TopViewer.PlaybackControls({
        engine: this
      });
      this.renderingControls = new TopViewer.RenderingControls({
        engine: this
      });
      this.uiAreas.push(this.playbackControls);
      this.uiAreas.push(this.renderingControls);
      this._frameTime = 0;
      this._frameCount = 0;
      this.gradientData = new Uint8Array(1024 * 4);
      this.gradientTexture = new THREE.DataTexture(this.gradientData, 1024, 1, THREE.RGBAFormat, THREE.UnsignedByteType);
      this.loadGradient(this.options.resourcesPath + 'gradients/xpost.png');
      this.gradientCurveData = new Float32Array(4096);
      this.gradientCurveTexture = new THREE.DataTexture(this.gradientCurveData, 4096, 1, THREE.AlphaFormat, THREE.FloatType, THREE.UVMapping, THREE.ClampToEdgeWrapping, THREE.ClampToEdgeWrapping, THREE.LinearFilter, THREE.LinearFilter);
    }

    Engine.prototype.loadGradient = function(url) {
      var image;
      image = new Image();
      image.onload = (function(_this) {
        return function() {
          var canvas, i, j, ref, uintData;
          canvas = document.createElement('canvas');
          canvas.width = 1024;
          canvas.height = 1;
          canvas.getContext('2d').drawImage(image, 0, 0, 1024, 1);
          uintData = canvas.getContext('2d').getImageData(0, 0, 1024, 1).data;
          for (i = j = 0, ref = uintData.length; 0 <= ref ? j < ref : j > ref; i = 0 <= ref ? ++j : --j) {
            _this.gradientData[i] = uintData[i];
          }
          return _this.gradientTexture.needsUpdate = true;
        };
      })(this);
      return image.src = url;
    };

    Engine.prototype.destroy = function() {
      this.scene.destroy();
      return this.playbackControls.destroy();
    };

    Engine.prototype.toggleShadows = function() {
      this.shadows = !this.shadows;
      return this.scene.update();
    };

    Engine.prototype.toggleVertexColors = function() {
      this.vertexColors = !this.vertexColors;
      return this.scene.update();
    };

    Engine.prototype.toggleReflections = function() {
      this.reflections = !this.reflections;
      return this.scene.update();
    };

    Engine.prototype.toggleDirectionalLight = function() {
      this.directionalLight = !this.directionalLight;
      return this.scene.update();
    };

    Engine.prototype.toggleAmbientLight = function() {
      this.ambientLight = !this.ambientLight;
      return this.scene.update();
    };

    Engine.prototype.toggleSurface = function() {
      return this.renderingControls.surfaceControl.setValue(!this.renderingControls.surfaceControl.value);
    };

    Engine.prototype.toggleWireframe = function() {
      return this.renderingControls.wireframeControl.setValue(!this.renderingControls.wireframeControl.value);
    };

    Engine.prototype.resize = function(width, height) {
      this.camera.aspect = width / height;
      this.camera.updateProjectionMatrix();
      this.renderer.setSize(width, height);
      return this.renderer.setViewport(0, 0, this.renderer.context.drawingBufferWidth, this.renderer.context.drawingBufferHeight);
    };

    Engine.prototype.draw = function(elapsedTime) {
      var azimuthal, euler, frameIndex, frameTime, i, j, k, l, len, len1, model, polar, ref, ref1, ref2, uiArea;
      this.uiControlsActive = false;
      ref = this.uiAreas;
      for (j = 0, len = ref.length; j < len; j++) {
        uiArea = ref[j];
        if (uiArea.rootControl.hover) {
          this.uiControlsActive = true;
        }
      }
      if (this.activeControls === this.rotateControls) {
        this.rotateControls.update();
        azimuthal = this.rotateControls.getAzimuthalAngle();
        polar = -this.rotateControls.getPolarAngle();
        euler = new THREE.Euler(polar, azimuthal, 0, 'XYZ');
        this.objectRotation = new THREE.Matrix4().makeRotationFromEuler(euler);
        this.scene.updateRotation();
      } else if (this.activeControls === this.cameraControls) {
        this.cameraControls.update();
      }
      if (this._gradientMapLastUpdate !== this.renderingControls.gradientCurve.lastUpdated) {
        this._gradientMapLastUpdate = this.renderingControls.gradientCurve.lastUpdated;
        for (i = k = 0; k < 4096; i = ++k) {
          this.gradientCurveData[i] = this.renderingControls.gradientCurve.getY(i / 4096);
        }
        this.gradientCurveTexture.needsUpdate = true;
      }
      this.playbackControls.update(elapsedTime);
      frameIndex = this.playbackControls.currentFrameIndex;
      frameTime = (ref1 = this.animation.frameTimes[frameIndex]) != null ? ref1 : -1;
      ref2 = this.scene.children;
      for (l = 0, len1 = ref2.length; l < len1; l++) {
        model = ref2[l];
        if (model instanceof TopViewer.Model) {
          model.showFrame(frameTime);
        }
      }
      this.renderer.render(this.scene, this.camera);
      this._frameCount++;
      this._frameTime += elapsedTime;
      if (this._frameTime > 1) {
        this._frameCount = 0;
        return this._frameTime = 0;
      }
    };

    Engine.prototype.onMouseDown = function(position, button) {
      var j, len, ref, results, uiArea;
      if (!this.uiControlsActive) {
        this.activeControls.mouseDown(position.x, position.y, this.buttonIndexFromString(button));
      }
      ref = this.uiAreas;
      results = [];
      for (j = 0, len = ref.length; j < len; j++) {
        uiArea = ref[j];
        results.push(uiArea.onMouseDown(position, button));
      }
      return results;
    };

    Engine.prototype.onMouseMove = function(position) {
      var j, len, ref, results, uiArea;
      if (!this.uiControlsActive) {
        this.activeControls.mouseMove(position.x, position.y);
      }
      ref = this.uiAreas;
      results = [];
      for (j = 0, len = ref.length; j < len; j++) {
        uiArea = ref[j];
        results.push(uiArea.onMouseMove(position));
      }
      return results;
    };

    Engine.prototype.onMouseUp = function(position, button) {
      var j, len, ref, results, uiArea;
      if (!this.uiControlsActive) {
        this.activeControls.mouseUp(position.x, position.y, this.buttonIndexFromString(button));
      }
      ref = this.uiAreas;
      results = [];
      for (j = 0, len = ref.length; j < len; j++) {
        uiArea = ref[j];
        results.push(uiArea.onMouseUp(position, button));
      }
      return results;
    };

    Engine.prototype.onMouseScroll = function(delta) {
      if (!this.uiControlsActive) {
        return this.activeControls.scale(delta);
      }
    };

    Engine.prototype.buttonIndexFromString = function(button) {
      if (button === 'right') {
        return 2;
      } else {
        return 0;
      }
    };

    return Engine;

  })();

}).call(this);

//# sourceMappingURL=engine.js.map