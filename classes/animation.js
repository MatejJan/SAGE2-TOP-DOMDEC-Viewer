// Generated by CoffeeScript 1.10.0
(function() {
  'use strict';
  TopViewer.Animation = (function() {
    function Animation(options) {
      this.options = options;
      this.frameTimes = [];
      this.length = 0;
      this.clientMaxLengths = {};
      this.clientMaxLengths[window.clientID] = 0;
    }

    Animation.prototype.addFrameTime = function(time) {
      return this.addFrameTimes([time]);
    };

    Animation.prototype.addFrameTimes = function(times) {
      var animationUpdateData;
      this.frameTimes = _.union(this.frameTimes, times);
      this.frameTimes.sort(function(a, b) {
        return a - b;
      });
      animationUpdateData = {
        clientId: window.clientID,
        framesCount: this.frameTimes.length
      };
      return this.options.engine.options.app.broadcast('animationUpdate', animationUpdateData);
    };

    Animation.prototype.onAnimationUpdate = function(data) {
      var clientId, framesCount, maxLength, ref;
      this.clientMaxLengths[data.clientId] = data.framesCount;
      maxLength = this.clientMaxLengths[window.clientID];
      ref = this.clientMaxLengths;
      for (clientId in ref) {
        framesCount = ref[clientId];
        maxLength = Math.min(maxLength, framesCount);
      }
      if (window.isMaster) {
        return this.options.engine.options.app.broadcast('animationUpdate', {
          maxLength: maxLength
        });
      }
    };

    return Animation;

  })();

}).call(this);

//# sourceMappingURL=animation.js.map
