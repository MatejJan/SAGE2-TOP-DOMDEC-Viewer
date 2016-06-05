'use strict'

class TopViewer.PlaybackControls extends TopViewer.UIArea
  constructor: (@options) ->
    super

    @$appWindow = @options.engine.$appWindow
    @animation = @options.engine.animation

    @$controls = $("""
      <div class="playback-controls">
        <div class="play-pause">
          <button class="play button icon-play"></button>
          <button class="pause button icon-pause"></button>
        </div>
        <div class="load-sleep">
          <button class="load button icon-loading"></button>
          <button class="sleep button icon-loading animate-spin"></button>
        </div>
        <div class="scrubber">
          <div class="timeline">
            <div class="ready-range"></div>
            <div class="playhead"></div>
          </div>
        </div>
      </div>
    """)

    @$appWindow.append(@$controls)

    $play = @$controls.find('.play')
    $pause = @$controls.find('.pause')

    $sleep = @$controls.find('.sleep')
    $load = @$controls.find('.load')

    @$scrubber = @$controls.find('.scrubber')
    $timeline = @$scrubber.find('.timeline')
    $readyRange = $timeline.find('.ready-range')
    @$playhead = $timeline.find('.playhead')

    # Set the root UI control.
    @rootControl = new TopViewer.UIControl @, @$controls

    playControl = new TopViewer.UIControl @, $play
    pauseControl = new TopViewer.UIControl @, $pause
    sleepControl = new TopViewer.UIControl @, $sleep
    loadControl = new TopViewer.UIControl @, $load
    scrubberControl = new TopViewer.UIControl @, @$scrubber

    # Make a control to handle hovering.
    new TopViewer.SliderControl @,
      $parent: @$controls
      class: 'speed'
      unit: 'FPS'
      minimumValue: 1
      maximumValue: 60
      value: 30
      onChange: (value) =>
        @framesPerSecond = value

    playControl.click =>
      @play()

    pauseControl.click =>
      @pause()

    sleepControl.click =>
      @sleep()

    loadControl.click =>
      @load()

    scrubberControl.mousedown (position, button) =>
      @_scrubbing = true
      @$controls.addClass('scrubbing')
      @handleScrubber position, button

    # Create frame blocks.
    ###
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

      # Check if animation has finished loading.
      if @animation.readyLength is @animation.length
        @loading = false
        @$controls.removeClass('loading')
        @$controls.addClass('loaded')
    ###

    @currentFrameIndex = 0
    @currentTime = 0

  destroy: ->
    super

    @animation = null

  # Playback
  play: ->
    @playing = true
    @$controls.addClass('playing')

  pause: ->
    @playing = false
    @$controls.removeClass('playing')

  # Loading
  load: ->
    @loading = true
    @animation.processLoadQueue()
    @$controls.addClass('loading')

  sleep: ->
    @loading = false
    @$controls.removeClass('loading')

  togglePlay: ->
    if @playing then @pause() else @play()

  nextFrame: ->
    return unless @animation.frameTimes.length

    @currentTime++
    while @currentTime >= @animation.frameTimes.length
      @currentTime -= @animation.frameTimes.length

    @onUpdateCurrentTime()

  previousFrame: ->
    return unless @animation.frameTimes.length

    @currentTime--
    while @currentTime < 0
      @currentTime += @animation.frameTimes.length

    @onUpdateCurrentTime()

  update: (elapsedTime) ->
    return unless @playing and not @_scrubbing and @animation.frameTimes.length

    @currentTime += elapsedTime * @framesPerSecond
    while @currentTime > @animation.frameTimes.length
      @currentTime -= @animation.frameTimes.length

    @onUpdateCurrentTime()

  onUpdateCurrentTime: ->
    @currentFrameIndex = Math.floor @currentTime

    playPercentage = 100.0 * @currentTime / @animation.frameTimes.length
    @$playhead.css
      left: "#{playPercentage}%"

  onMouseMove: (position) ->
    super

    @handleScrubber position if @_scrubbing

  onMouseUp: (position, button) ->
    super

    @_scrubbing = false
    @$controls.removeClass('scrubbing')

  handleScrubber: (position) ->
    mouseXBrowser = @$appWindow.offset().left + position.x
    scrubberX = mouseXBrowser - @$scrubber.offset().left
    playPercentage = scrubberX / @$scrubber.width()
    newCurrentTime = playPercentage * @animation.length

    # Make sure we're inside the bounds of animation Length.
    newCurrentTime = Math.min @animation.frameTimes.length - 0.001, Math.max 0, newCurrentTime

    @currentTime = newCurrentTime
    @onUpdateCurrentTime()
