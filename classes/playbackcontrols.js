// Generated by CoffeeScript 1.10.0
(function() {
  'use strict';
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  TopViewer.PlaybackControls = (function(superClass) {
    extend(PlaybackControls, superClass);

    function PlaybackControls(options) {
      var $load, $pause, $play, $readyRange, $sleep, $timeline, loadControl, pauseControl, playControl, saveState, scrubberControl, sleepControl;
      this.options = options;
      PlaybackControls.__super__.constructor.apply(this, arguments);
      saveState = this.options.engine.options.app.state.playbackControls;
      this.$appWindow = this.options.engine.$appWindow;
      this.animation = this.options.engine.animation;
      this.$controls = $("<div class=\"playback-controls\">\n  <div class=\"play-pause\">\n    <button class=\"play button icon-play\"></button>\n    <button class=\"pause button icon-pause\"></button>\n  </div>\n  <div class=\"load-sleep\">\n    <button class=\"load button icon-loading\"></button>\n    <button class=\"sleep button icon-loading animate-spin\"></button>\n  </div>\n  <div class=\"scrubber\">\n    <div class=\"timeline\">\n      <div class=\"ready-range\"></div>\n      <div class=\"playhead\"></div>\n    </div>\n  </div>\n</div>");
      this.$appWindow.append(this.$controls);
      $play = this.$controls.find('.play');
      $pause = this.$controls.find('.pause');
      $sleep = this.$controls.find('.sleep');
      $load = this.$controls.find('.load');
      this.$scrubber = this.$controls.find('.scrubber');
      $timeline = this.$scrubber.find('.timeline');
      $readyRange = $timeline.find('.ready-range');
      this.$playhead = $timeline.find('.playhead');
      this.$rootElement = this.$controls;
      this.rootControl = new TopViewer.UIControl(this, this.$controls);
      playControl = new TopViewer.UIControl(this, $play);
      pauseControl = new TopViewer.UIControl(this, $pause);
      sleepControl = new TopViewer.UIControl(this, $sleep);
      loadControl = new TopViewer.UIControl(this, $load);
      scrubberControl = new TopViewer.UIControl(this, this.$scrubber);
      this.framesPerSecondControl = new TopViewer.SliderControl(this, {
        $parent: this.$controls,
        "class": 'speed',
        unit: 'FPS',
        minimumValue: 1,
        maximumValue: 60,
        value: saveState.fps,
        onChange: (function(_this) {
          return function(value) {
            return saveState.fps = value;
          };
        })(this)
      });
      playControl.click((function(_this) {
        return function() {
          return _this.play();
        };
      })(this));
      pauseControl.click((function(_this) {
        return function() {
          return _this.pause();
        };
      })(this));
      sleepControl.click((function(_this) {
        return function() {
          return _this.sleep();
        };
      })(this));
      loadControl.click((function(_this) {
        return function() {
          return _this.load();
        };
      })(this));
      scrubberControl.mousedown((function(_this) {
        return function(position, button) {
          _this._scrubbing = true;
          _this.$controls.addClass('scrubbing');
          return _this.handleScrubber(position, button);
        };
      })(this));

      /*
      blocks = []
      blocksCount = @animation.length
      blockWidth = 100 / blocksCount
      for i in [0...blocksCount]
        do (i) ->
          $block = $('<div class="frame">')
          $block.css
            left: "#{i * blockWidth}%"
            width: "#{blockWidth}%"
      
          $blockProgress = $('<div class="progress">')
          $block.append($blockProgress)
          $timeline.append($block)
      
          blocks[i] =
            $block: $block
            $blockProgress: $blockProgress
      
      @animation.onLoadProgress = (frameIndex, loadPercentage) ->
        blocks[frameIndex].$blockProgress.css
          width: "#{loadPercentage}%"
      
      @animation.onUpdated = =>
        readyPercentage = 100.0 * @animation.readyLength / @animation.length
        $readyRange.css
          width: "#{readyPercentage}%"
      
         * Check if animation has finished loading.
        if @animation.readyLength is @animation.length
          @loading = false
          @$controls.removeClass('loading')
          @$controls.addClass('loaded')
       */
      this.currentFrameIndex = 0;
      this.currentTime = 0;
      this.initialize();
    }

    PlaybackControls.prototype.destroy = function() {
      PlaybackControls.__super__.destroy.apply(this, arguments);
      return this.animation = null;
    };

    PlaybackControls.prototype.play = function() {
      this.playing = true;
      return this.$controls.addClass('playing');
    };

    PlaybackControls.prototype.pause = function() {
      this.playing = false;
      return this.$controls.removeClass('playing');
    };

    PlaybackControls.prototype.load = function() {
      this.loading = true;
      this.animation.processLoadQueue();
      return this.$controls.addClass('loading');
    };

    PlaybackControls.prototype.sleep = function() {
      this.loading = false;
      return this.$controls.removeClass('loading');
    };

    PlaybackControls.prototype.togglePlay = function() {
      if (this.playing) {
        return this.pause();
      } else {
        return this.play();
      }
    };

    PlaybackControls.prototype.nextFrame = function() {
      if (!this.animation.length) {
        return;
      }
      this.currentTime++;
      while (this.currentTime >= this.animation.length) {
        this.currentTime -= this.animation.length;
      }
      return this.onUpdateCurrentTime();
    };

    PlaybackControls.prototype.previousFrame = function() {
      if (!this.animation.length) {
        return;
      }
      this.currentTime--;
      while (this.currentTime < 0) {
        this.currentTime += this.animation.length;
      }
      return this.onUpdateCurrentTime();
    };

    PlaybackControls.prototype.setCurrentTime = function(currentTime) {
      this.currentTime = Math.max(0, Math.min(this.animation.length, currentTime));
      return this.onUpdateCurrentTime();
    };

    PlaybackControls.prototype.update = function(elapsedTime) {
      if (!(this.playing && !this._scrubbing && this.animation.length)) {
        return;
      }
      this.currentTime += elapsedTime * this.framesPerSecondControl.value;
      while (this.currentTime > this.animation.length) {
        this.currentTime -= this.animation.length;
      }
      return this.onUpdateCurrentTime();
    };

    PlaybackControls.prototype.onUpdateCurrentTime = function() {
      var playPercentage;
      this.currentFrameIndex = Math.floor(this.currentTime);
      playPercentage = 100.0 * this.currentTime / this.animation.length;
      return this.$playhead.css({
        left: playPercentage + "%"
      });
    };

    PlaybackControls.prototype.onMouseMove = function(position) {
      PlaybackControls.__super__.onMouseMove.apply(this, arguments);
      if (this._scrubbing) {
        return this.handleScrubber(position);
      }
    };

    PlaybackControls.prototype.onMouseUp = function(position, button) {
      PlaybackControls.__super__.onMouseUp.apply(this, arguments);
      this._scrubbing = false;
      return this.$controls.removeClass('scrubbing');
    };

    PlaybackControls.prototype.handleScrubber = function(position) {
      var mouseXBrowser, newCurrentTime, playPercentage, scrubberX;
      mouseXBrowser = this.$appWindow.offset().left + position.x;
      scrubberX = mouseXBrowser - this.$scrubber.offset().left;
      playPercentage = scrubberX / this.$scrubber.width();
      newCurrentTime = playPercentage * this.animation.length;
      newCurrentTime = Math.min(this.animation.length - 0.001, Math.max(0, newCurrentTime));
      this.currentTime = newCurrentTime;
      return this.onUpdateCurrentTime();
    };

    return PlaybackControls;

  })(TopViewer.UIArea);

}).call(this);

//# sourceMappingURL=playbackcontrols.js.map
