// Generated by CoffeeScript 1.10.0
(function() {
  'use strict';
  TopViewer.UIArea = (function() {
    function UIArea($appWindow) {
      this.$appWindow = $appWindow;
      this._controls = [];
    }

    UIArea.prototype.destroy = function() {
      var control, i, len, ref;
      this.$appWindow = null;
      ref = this._controls;
      for (i = 0, len = ref.length; i < len; i++) {
        control = ref[i];
        if (typeof control.destroy === "function") {
          control.destroy();
        }
      }
      return this._controls = null;
    };

    UIArea.prototype.addControl = function(control) {
      return this._controls.push(control);
    };

    UIArea.prototype.onMouseDown = function(position, button) {
      var control, i, len, ref, results;
      ref = this._controls;
      results = [];
      for (i = 0, len = ref.length; i < len; i++) {
        control = ref[i];
        results.push(control.onMouseDown(position, button));
      }
      return results;
    };

    UIArea.prototype.onMouseMove = function(position) {
      var control, i, len, ref, results;
      ref = this._controls;
      results = [];
      for (i = 0, len = ref.length; i < len; i++) {
        control = ref[i];
        results.push(control.onMouseMove(position));
      }
      return results;
    };

    UIArea.prototype.onMouseUp = function(position, button) {
      var control, i, len, ref, results;
      ref = this._controls;
      results = [];
      for (i = 0, len = ref.length; i < len; i++) {
        control = ref[i];
        results.push(control.onMouseUp(position, button));
      }
      return results;
    };

    return UIArea;

  })();

}).call(this);

//# sourceMappingURL=uiarea.js.map