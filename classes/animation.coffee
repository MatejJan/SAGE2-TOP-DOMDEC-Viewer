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

    # Communicate how many frames we have available.
    @options.engine.options.app.broadcast 'animationUpdate', animationUpdateData

  onAnimationUpdate: (data) ->
    @clientMaxLengths[data.clientId] = data.framesCount

    maxLength = @clientMaxLengths[window.clientID]
    
    # Maximum available playback length is the minimum of all lengths
    # of all clients (the length of the one who loaded the least)
    for clientId, framesCount of @clientMaxLengths
      maxLength = Math.min maxLength, framesCount

    # The master's maxLength calculation is the one that should be applied across the system.
    if window.isMaster
      @options.engine.options.app.broadcast 'animationUpdate',
        maxLength: maxLength
