class TopViewer.VertexColorsControl
  constructor: (@uiArea, @options) ->
    @value = @options.value

    @$element = $("<div class='vertex-colors-control #{@options.class}'></div>")
    @options.$parent.append(@$element)

    @typeControl = new TopViewer.DropdownControl @uiArea,
      $parent: @$element
      class: 'vertex-colors-type'
      onChange: (value) =>
        @options.saveState.type = value

        @$element.find('.sub-area').removeClass('displayed')

        switch value
          when TopViewer.RenderingControls.VertexColorsType.Color then $displayArea = @$colorArea
          when TopViewer.RenderingControls.VertexColorsType.Scalar then $displayArea = @$scalarArea

        $displayArea.addClass('displayed')

    @typeControl.addValue 'Color', TopViewer.RenderingControls.VertexColorsType.Color
    @typeControl.addValue 'Scalar', TopViewer.RenderingControls.VertexColorsType.Scalar

    @$colorArea = $("<div class='color-area sub-area'></div>")
    @$element.append(@$colorArea)

    @colorControl = new TopViewer.ColorControl @uiArea,
      $parent: @$colorArea
      saveState: @options.saveState.color

    @$scalarArea = $("<div class='scalar-area sub-area'></div>")
    @$element.append(@$scalarArea)

    @scalarControl = new TopViewer.ScalarControl @uiArea,
      $parent: @$scalarArea
      saveState: @options.saveState.scalar

    @typeControl.setValue @options.saveState.type
