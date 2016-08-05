class TopViewer.ToggleContainer
  constructor: (@uiArea, @options) ->
    @$element = $("""
      <div class="toggle-container #{@options.class}">
        <div class='toggle'></div>
        <div class='contents #{if @options.visible then 'visible' else 'hidden'}'></div>
      </div>
    """)

    $toggle = @$element.find('.toggle')
    $contents = @$element.find('.contents')
    $contents.append @options.$contents

    @toggleControl = new TopViewer.CheckboxControl @uiArea,
      $parent: $toggle
      name: @options.text
      value: @options.visible
      onChange: (value) =>
        if value
          $contents.addClass('visible').removeClass('hidden')

        else
          $contents.addClass('hidden').removeClass('visible')

    @options.$parent.append(@$element)

    # Create the top UI control for hovering purposes.
    new TopViewer.UIControl @uiArea, @$element

  setText: (text) ->
    @options.text = text
    @toggleControl.setName text
