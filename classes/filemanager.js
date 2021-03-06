// Generated by CoffeeScript 1.10.0
(function() {
  'use strict';
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  TopViewer.FileManager = (function(superClass) {
    extend(FileManager, superClass);

    function FileManager(options) {
      var saveState, scrollOffset;
      this.options = options;
      FileManager.__super__.constructor.apply(this, arguments);
      saveState = this.options.engine.options.app.state.fileManager;
      this.$appWindow = this.options.engine.$appWindow;
      this.scene = this.options.engine.scene;
      this.$manager = $("<div class='file-manager'>");
      this.$appWindow.append(this.$manager);
      this.$rootElement = this.$manager;
      this.rootControl = new TopViewer.UIControl(this, this.$manager);
      scrollOffset = 0;
      this.rootControl.scroll((function(_this) {
        return function(delta) {
          scrollOffset += delta;
          scrollOffset = Math.max(scrollOffset, 0);
          scrollOffset = Math.min(scrollOffset, _this.$controls.height() - _this.options.engine.$appWindow.height() * 0.8);
          return _this.$controls.css({
            top: -scrollOffset
          });
        };
      })(this));
      this.$filesArea = $("<ul class='files'></ul>");
      new TopViewer.ToggleContainer(this, {
        $parent: this.$manager,
        text: "Files",
        "class": 'panel',
        visible: saveState.files.panelEnabled,
        $contents: this.$filesArea,
        onChange: (function(_this) {
          return function(value) {
            return saveState.files.panelEnabled = value;
          };
        })(this)
      });
      this.files = {};
      this.initialize();
      this.options.engine.uiAreas.push(this);
    }

    FileManager.prototype.addFile = function(file) {
      var $contents, $file, $fileSize, $loadProgress, $name, fileContainer;
      $file = $("<li class='file'></li>");
      this.$filesArea.append($file);
      $contents = $("<div>");
      fileContainer = new TopViewer.ToggleContainer(this, {
        $parent: $file,
        text: file.filename,
        "class": 'file-container',
        visible: false,
        $contents: $contents
      });
      $loadProgress = $('<span class="load-progress">');
      $name = fileContainer.toggleControl.$element.find('.name');
      $name.append($loadProgress);
      $fileSize = $('<span class="file-size">');
      $name.after($fileSize);
      file.options.onSize = (function(_this) {
        return function(size) {
          var unitIndex, units;
          units = ['B', 'kB', 'MB', 'GB'];
          unitIndex = 0;
          while (size > 100) {
            size /= 1000;
            unitIndex++;
          }
          return $fileSize.text("" + (Math.round10(size, -1)) + units[unitIndex]);
        };
      })(this);
      file.options.onProgress = (function(_this) {
        return function(percentage) {
          return $loadProgress.css('width', percentage + "%");
        };
      })(this);
      return file.options.onComplete = (function(_this) {
        return function() {
          return $name.addClass('loaded');
        };
      })(this);
    };

    FileManager.prototype.initializeFiles = function(fileListData) {
      var file, fileData, fileFolder, filenameStartIndex, i, len, ref, targetFolder, url;
      if (!this.options.targetFile) {
        return;
      }
      filenameStartIndex = this.options.targetFile.lastIndexOf('/') + 1;
      targetFolder = this.options.targetFile.substring(0, filenameStartIndex);
      this.files = {};
      ref = fileListData.others;
      for (i = 0, len = ref.length; i < len; i++) {
        fileData = ref[i];
        url = fileData.sage2URL;
        fileFolder = url.substring(0, url.lastIndexOf('/') + 1);
        if (targetFolder !== fileFolder) {
          continue;
        }
        file = new TopViewer.File({
          url: url,
          onResults: (function(_this) {
            return function(objects) {
              return _this._addObjects(objects);
            };
          })(this)
        });
        this.addFile(file);
        this.files[url] = file;
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
        items: _.values(this.files),
        methodName: 'load'
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
      var elements, elementsInstance, elementsName, elementsType, nodesInstance, nodesName, ref, ref1, ref2, ref3, ref4, results, scalar, scalarName, scalarNodesName, scalars, vector, vectorName, vectorNodesName, vectors;
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
          ref2 = elementsInstance.elements;
          for (elementsType in ref2) {
            elements = ref2[elementsType];
            this.models[elementsInstance.nodesName].addElements(elementsName, parseInt(elementsType), elements);
            delete this.objects.elements[elementsName];
          }
        }
      }
      ref3 = this.objects.scalars;
      for (scalarNodesName in ref3) {
        scalars = ref3[scalarNodesName];
        if (this.models[scalarNodesName]) {
          for (scalarName in scalars) {
            scalar = scalars[scalarName];
            this.models[scalarNodesName].addScalar(scalarName, scalar);
          }
          delete this.objects.scalars[scalarNodesName];
        }
      }
      ref4 = this.objects.vectors;
      results = [];
      for (vectorNodesName in ref4) {
        vectors = ref4[vectorNodesName];
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

  })(TopViewer.UIArea);

}).call(this);

//# sourceMappingURL=filemanager.js.map
