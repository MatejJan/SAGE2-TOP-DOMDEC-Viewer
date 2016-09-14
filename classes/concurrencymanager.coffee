class TopViewer.ConcurrencyManager
  constructor: (@options) ->
    @_concurrentItemsRunning = 0
    @_maxConcurrentItemsRunning = 4

    @_nextItemIndexToRun = 0
    @_itemsCompleted = 0

    @_runStart = new Date()

    @processRunQueue()

  processRunQueue: ->
    return unless @_nextItemIndexToRun?

    # Stop when we reach the end of the items.
    return if @_nextItemIndexToRun >= @options.items.length

    # Don't run if we're at the limit of concurrent runs.
    return if @_concurrentItemsRunning >= @_maxConcurrentItemsRunning

    item = @options.items[@_nextItemIndexToRun]

    item[@options.methodName] =>
      @_itemsCompleted++

      # We have completed loading this frame so try to load a new one.
      @_concurrentItemsRunning--
      @processRunQueue()

      @options.onProgress? @progress(), item

      @_complete() if @_itemsCompleted is @options.items.length

    # Increment frames.
    @_nextItemIndexToRun++
    @_concurrentItemsRunning++

    # Keep on loading so we hit the concurrency limit.
    @processRunQueue()

  progress: ->
    @_itemsCompleted / @options.items.length

  _complete: ->
    runEnd = new Date()
    runTime = runEnd - @_runStart #ms
    console.log "Concurrency manager completed in #{runTime}ms"

    @options.onComplete?()
