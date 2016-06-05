// Generated by CoffeeScript 1.10.0
(function() {
  'use strict';
  TopViewer.FileManager = (function() {
    function FileManager(options) {
      this.options = options;
    }

    FileManager.prototype.initialize = function(fileListData) {
      var file, fileFolder, filenameStartIndex, i, len, ref, targetFolder, url;
      if (!this.options.targetFile) {
        return;
      }
      filenameStartIndex = this.options.targetFile.lastIndexOf('/') + 1;
      targetFolder = this.options.targetFile.substring(0, filenameStartIndex);
      this.urls = {};
      ref = fileListData.others;
      for (i = 0, len = ref.length; i < len; i++) {
        file = ref[i];
        url = file.sage2URL;
        fileFolder = url.substring(0, url.lastIndexOf('/') + 1);
        if (targetFolder !== fileFolder) {
          continue;
        }
        this.urls[url] = new TopViewer.File(url);
      }
      this.objects = {
        nodes: {},
        elements: {},
        vectors: {},
        scalars: {}
      };
      this.scalarLimits = {};
      this.models = {};
      return new TopViewer.ConcurrencyManager({
        items: _.values(this.urls),
        methodName: 'load',
        onProgress: (function(_this) {
          return function(progress, item) {
            console.log("Loaded " + (Math.floor(progress * 100)) + "% of files.");
            return _this._addObjects(item.objects);
          };
        })(this),
        onComplete: (function(_this) {
          return function() {};
        })(this)
      });
    };

    FileManager.prototype._addObjects = function(objects) {
      var base, base1, base2, elementsInstance, elementsName, frame, i, len, limits, nodesInstance, nodesName, ref, ref1, ref2, ref3, ref4, scalar, scalarName, scalarNodesName, scalars, vector, vectorName, vectorNodesName, vectors;
      ref = objects.nodes;
      for (nodesName in ref) {
        nodesInstance = ref[nodesName];
        this.objects.nodes[nodesName] = nodesInstance;
      }
      ref1 = objects.elements;
      for (elementsName in ref1) {
        elementsInstance = ref1[elementsName];
        this.objects.elements[elementsName] = elementsInstance;
      }
      ref2 = objects.scalars;
      for (scalarNodesName in ref2) {
        scalars = ref2[scalarNodesName];
        if ((base = this.objects.scalars)[scalarNodesName] == null) {
          base[scalarNodesName] = {};
        }
        for (scalarName in scalars) {
          scalar = scalars[scalarName];
          this.objects.scalars[scalarNodesName][scalarName] = scalar;
          if ((base1 = this.scalarLimits)[scalarName] == null) {
            base1[scalarName] = {
              minValue: null,
              maxValue: null,
              version: 0
            };
          }
          limits = this.scalarLimits[scalarName];
          ref3 = scalar.frames;
          for (i = 0, len = ref3.length; i < len; i++) {
            frame = ref3[i];
            if (!((limits.minValue != null) && limits.minValue < frame.minValue)) {
              limits.minValue = frame.minValue;
            }
            if (!((limits.maxValue != null) && limits.maxValue > frame.maxValue)) {
              limits.maxValue = frame.maxValue;
            }
          }
          scalar.limits = limits;
          limits.version++;
        }
      }
      ref4 = objects.vectors;
      for (vectorNodesName in ref4) {
        vectors = ref4[vectorNodesName];
        if ((base2 = this.objects.vectors)[vectorNodesName] == null) {
          base2[vectorNodesName] = {};
        }
        for (vectorName in vectors) {
          vector = vectors[vectorName];
          this.objects.vectors[vectorNodesName][vectorName] = vector;
        }
      }
      return this._processObjects();
    };

    FileManager.prototype._processObjects = function() {
      var elementsInstance, elementsName, nodesInstance, nodesName, ref, ref1, ref2, ref3, results, scalar, scalarName, scalarNodesName, scalars, vector, vectorName, vectorNodesName, vectors;
      ref = this.objects.nodes;
      for (nodesName in ref) {
        nodesInstance = ref[nodesName];
        this.models[nodesName] = new TopViewer.Model({
          engine: this.options.engine,
          nodes: nodesInstance.nodes
        });
        delete this.objects.nodes[nodesName];
      }
      ref1 = this.objects.elements;
      for (elementsName in ref1) {
        elementsInstance = ref1[elementsName];
        if (this.models[elementsInstance.nodesName]) {
          this.models[elementsInstance.nodesName].addElements(elementsName, elementsInstance);
          delete this.objects.elements[elementsName];
        }
      }
      ref2 = this.objects.scalars;
      for (scalarNodesName in ref2) {
        scalars = ref2[scalarNodesName];
        if (this.models[scalarNodesName]) {
          for (scalarName in scalars) {
            scalar = scalars[scalarName];
            this.models[scalarNodesName].addScalar(scalarName, scalar);
          }
          delete this.objects.scalars[scalarNodesName];
        }
      }
      ref3 = this.objects.vectors;
      results = [];
      for (vectorNodesName in ref3) {
        vectors = ref3[vectorNodesName];
        if (this.models[vectorNodesName]) {
          for (vectorName in vectors) {
            vector = vectors[vectorName];
            this.models[vectorNodesName].addVector(vectorName, vector);
          }
          results.push(delete this.objects.vectors[vectorNodesName]);
        } else {
          results.push(void 0);
        }
      }
      return results;
    };

    return FileManager;

  })();

}).call(this);

//# sourceMappingURL=filemanager.js.map