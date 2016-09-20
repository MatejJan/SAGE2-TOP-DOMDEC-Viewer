'use strict'

class TopViewer.Animation
  constructor: (@options) ->
    @frameTimes = []
    @length = 0

    @clientMaxLengths = {}
    @clientMaxLengths[window.clientID] = 0

  addFrameTime: (time) ->
    @addFrameTimes [time]

  addFrameTimes: (times) ->
    @frameTimes = _.union @frameTimes, times

    @frameTimes.sort (a, b) ->
      a - b

    animationUpdateData =
      clientId: window.clientID
      framesCount: @frameTimes.length

    console.log "added frames", animationUpdateData

    if window.isMaster
      @onAnimationUpdate animationUpdateData

    else
      # Communicate to master how many frames we have available.
      @options.engine.options.app.broadcast 'animationUpdate', animationUpdateData

  onAnimationUpdate: (data) ->
    @clientMaxLengths[data.clientId] = data.framesCount

    maxLength = @clientMaxLengths[window.clientID]
    
    # Maximum available playback length is the minimum of all lengths
    # of all clients (the length of the one who loaded the least)
    for clientId, framesCount of @clientMaxLengths
      maxLength = Math.min maxLength, framesCount

    @length = maxLength

    console.log "figured out new length", maxLength

    @options.engine.options.app.broadcast 'animationUpdate',
      maxLength: maxLength
