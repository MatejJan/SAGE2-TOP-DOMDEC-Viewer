// Generated by CoffeeScript 1.10.0
(function() {
  TopViewer.File = (function() {
    File.loaders = {
      top: new TopViewer.TopLoader
    };

    File.loaders.xpost = File.loaders.top;

    function File(options) {
      this.options = options;
      this.filename = this.options.url.split('/').pop();
      this.extension = this.filename.split('.').pop();
      this.loader = this.constructor.loaders[this.extension];
    }

    File.prototype.load = function(onCompleteHandler) {
      if (!this.loader) {
        setTimeout((function(_this) {
          return function() {
            _this.objects = {};
            return onCompleteHandler();
          };
        })(this), 0);
        return;
      }
      return this.loader.load({
        url: this.options.url,
        onSize: (function(_this) {
          return function(size) {
            var base;
            return typeof (base = _this.options).onSize === "function" ? base.onSize(size) : void 0;
          };
        })(this),
        onProgress: (function(_this) {
          return function(loadPercentage) {
            var base;
            return typeof (base = _this.options).onProgress === "function" ? base.onProgress(loadPercentage) : void 0;
          };
        })(this),
        onResults: (function(_this) {
          return function(objects) {
            var base;
            _this.objects = objects;
            return typeof (base = _this.options).onResults === "function" ? base.onResults(_this.objects) : void 0;
          };
        })(this),
        onComplete: (function(_this) {
          return function() {
            var base;
            if (typeof (base = _this.options).onComplete === "function") {
              base.onComplete();
            }
            return onCompleteHandler();
          };
        })(this)
      });
    };

    return File;

  })();

}).call(this);

//# sourceMappingURL=file.js.map
