// Generated by CoffeeScript 1.10.0
(function() {
  'use strict';
  TopViewer.Volume = (function() {
    function Volume(options) {
      var a, addLine, b, connectivity, height, i, isosurfacesCornerIndexArray, isosurfacesCornerIndexAttribute, isosurfacesGeometry, isosurfacesIndexArray, isosurfacesIndexAttribute, j, k, l, lineVertexIndex, linesCount, m, n, o, p, q, r, ref, ref1, ref2, ref3, setVertexIndexCoordinates, tetraCount, wireframeGeometry, wireframeIndexArray, wireframeIndexAttribute;
      this.options = options;
      height = this.options.model.basePositionsTexture.image.height;
      setVertexIndexCoordinates = function(attribute, i, index) {
        attribute.setX(i, index % 4096 / 4096);
        return attribute.setY(i, Math.floor(index / 4096) / height);
      };
      connectivity = [];
      linesCount = 0;
      addLine = function(a, b) {
        var ref;
        if (a > b) {
          ref = [b, a], a = ref[0], b = ref[1];
        }
        if (connectivity[a] == null) {
          connectivity[a] = {};
        }
        if (!connectivity[a][b]) {
          connectivity[a][b] = true;
          return linesCount++;
        }
      };
      for (i = l = 0, ref = this.options.elements.length / 4; 0 <= ref ? l < ref : l > ref; i = 0 <= ref ? ++l : --l) {
        addLine(this.options.elements[i * 4], this.options.elements[i * 4 + 1]);
        addLine(this.options.elements[i * 4 + 1], this.options.elements[i * 4 + 2]);
        addLine(this.options.elements[i * 4 + 2], this.options.elements[i * 4]);
        addLine(this.options.elements[i * 4], this.options.elements[i * 4 + 3]);
        addLine(this.options.elements[i * 4 + 1], this.options.elements[i * 4 + 3]);
        addLine(this.options.elements[i * 4 + 2], this.options.elements[i * 4 + 3]);
      }
      wireframeGeometry = new THREE.BufferGeometry();
      this.wireframeMesh = new THREE.LineSegments(wireframeGeometry, this.options.model.volumeWireframeMaterial);
      wireframeIndexArray = new Float32Array(linesCount * 4);
      wireframeIndexAttribute = new THREE.BufferAttribute(wireframeIndexArray, 2);
      lineVertexIndex = 0;
      for (a = m = 0, ref1 = connectivity.length; 0 <= ref1 ? m < ref1 : m > ref1; a = 0 <= ref1 ? ++m : --m) {
        if (!connectivity[a]) {
          continue;
        }
        for (b in connectivity[a]) {
          setVertexIndexCoordinates(wireframeIndexAttribute, lineVertexIndex, a);
          setVertexIndexCoordinates(wireframeIndexAttribute, lineVertexIndex + 1, b);
          lineVertexIndex += 2;
        }
      }
      wireframeGeometry.addAttribute('vertexIndex', wireframeIndexAttribute);
      wireframeGeometry.drawRange.count = linesCount * 2;
      isosurfacesGeometry = new THREE.BufferGeometry();
      this.isosurfacesMesh = new THREE.Mesh(isosurfacesGeometry, this.options.model.isosurfaceMaterial);
      tetraCount = this.options.elements.length / 4;
      for (i = n = 0; n <= 3; i = ++n) {
        isosurfacesIndexArray = new Float32Array(tetraCount * 12);
        isosurfacesIndexAttribute = new THREE.BufferAttribute(isosurfacesIndexArray, 2);
        for (j = o = 0, ref2 = tetraCount; 0 <= ref2 ? o < ref2 : o > ref2; j = 0 <= ref2 ? ++o : --o) {
          for (k = p = 0; p < 6; k = ++p) {
            setVertexIndexCoordinates(isosurfacesIndexAttribute, j * 6 + k, this.options.elements[j * 4 + i]);
          }
        }
        isosurfacesGeometry.addAttribute("vertexIndexCorner" + (i + 1), isosurfacesIndexAttribute);
      }
      isosurfacesCornerIndexArray = new Float32Array(tetraCount * 6);
      isosurfacesCornerIndexAttribute = new THREE.BufferAttribute(isosurfacesCornerIndexArray, 1);
      for (i = q = 0, ref3 = tetraCount; 0 <= ref3 ? q < ref3 : q > ref3; i = 0 <= ref3 ? ++q : --q) {
        for (k = r = 0; r < 6; k = ++r) {
          isosurfacesCornerIndexArray[i * 6 + k] = k * 0.1;
        }
      }
      isosurfacesGeometry.addAttribute("cornerIndex", isosurfacesCornerIndexAttribute);
      isosurfacesGeometry.drawRange.count = tetraCount * 6;
      this._updateGeometry();
      this.options.model.add(this.isosurfacesMesh);
      this.options.model.add(this.wireframeMesh);
      this.options.engine.renderingControls.addVolume(this.options.name, this);
    }

    Volume.prototype._updateGeometry = function() {
      this._updateBounds(this.wireframeMesh, this.options.model);
      return this._updateBounds(this.isosurfacesMesh, this.options.model);
    };

    Volume.prototype._updateBounds = function(mesh, model) {
      mesh.geometry.boundingBox = this.options.model.boundingBox;
      return mesh.geometry.boundingSphere = this.options.model.boundingSphere;
    };

    Volume.prototype.showFrame = function() {
      this.wireframeMesh.visible = this.options.engine.renderingControls.volumesShowWireframeControl.value();
      this.isosurfacesMesh.visible = this.options.engine.renderingControls.volumesShowIsosurfacesControl.value();
      this.isosurfacesMesh.receiveShadows = true;
      return this.isosurfacesMesh.castShadows = true;
    };

    return Volume;

  })();

}).call(this);

//# sourceMappingURL=volume.js.map
