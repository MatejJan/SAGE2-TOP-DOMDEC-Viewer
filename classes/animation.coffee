'use strict'

class TopViewer.Animation
  constructor: ->
    @frameTimes = []

  addFrameTime: (time) ->
    @addFrameTimes [time]

  addFrameTimes: (times) ->
    @frameTimes = _.union @frameTimes, times

    @frameTimes.sort (a, b) ->
      a - b
