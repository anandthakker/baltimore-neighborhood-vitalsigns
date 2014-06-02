angular.module('vitalsigns')

  .factory 'Choropleth', ()->

    ###
    * d3 Map Drawing
    * (See http://bost.ocks.org/mike/map/ and
    * http://bl.ocks.org/mbostock/4060606 )
    ###

    class Choropleth
      constructor: (svg, @feature) ->
        @svg = d3.select(svg)
        @projection = d3.geo.mercator()
          .scale(50000)
          .center([-76.6167, 39.2833])
          .translate([@width/2, @height/2])
        @path = d3.geo.path().projection(@projection)

      width: 200
      height: 200

      ###
      Hover handler (for regions)
      TODO: convert other accessors to this chainable style.
      ###
      _mouseover: (d, i) ->
      _mouseout: (d, i) ->
      hover: (_) =>
        if _?
          [@_mouseover, @_mouseout] = _
          return this
        else
          [@_mouseover, @_mouseout]

      _click: (d, i) ->
      click: (_) =>
        if _?
          @_click = _
        else
          return @_click

      ###
      Property value accessor. Takes a topojson feature as input, and should
      return the value to be mapped onto the color scale for that feature.
      ###
      value: (d) -> @_data[d]

      # method to compute the domain for our color scale
      domain: () => d3.extent @_data, @value


      # method to compute the range for our color scale
      colorRange: () =>
        d3.range(9).map (i) -> "q#{i}-9"

      data: (mapdata, data) =>
        @topojsonData = mapdata
        @_data = data
        @redraw()

      redraw: () =>
        feature = @topojsonData.objects[@feature]

        ###
        Rebuild quantizer each time, since domain and range could have changed
        (in typical d3 style, we'd just have the quantize function be accessible
        to client code, but since we want our default domain to be set when the
        data is provided, it works better to expose domain() as a method that
        can be overridden, and just build quantize from that... I think...)
        ###
        quantize = d3.scale.quantize()
          .domain(@domain())
          .range(@colorRange())

        @svg.attr("width", @width)
          .attr("height", @height)

        @svg.selectAll(".region")
          .data(topojson.feature(@topojsonData, feature).features)
          .enter()
          .append("path")
          .attr("d", @path)
          .attr("data-region", (d)->d.id)
          .attr("class", (d)=>
            q = quantize(@value(d))
            "region " + q
          ).on "mouseover", (d, i)=>@_mouseover(d,i)
          .on "mouseout", (d,i)=>@_mouseout(d,i)
          .on "click", (d,i)=>@_click(d,i)

        @svg.append("path")
          .datum(topojson.mesh(@topojsonData, feature))
          .attr("d", @path)
          .attr("class", "region-boundary");


  .factory 'Histogram', ()->
    ###
    * Histogram
    *
    ###

    class Histogram
      constructor: (svg) ->
        @svg = d3.select(svg)

      width: 200
      height: 100


      _mouseover: (d, i) ->
      _mouseout: (d, i) ->
      hover: (_) =>
        if _?
          [@_mouseover, @_mouseout] = _
          return this
        else
          [@_mouseover, @_mouseout]

      _click: (d, i) ->
      click: (_) =>
        if _?
          @_click = _
        else
          return @_click


      value: (d) => @_data[d]

      # method to compute the domain
      domain: () => d3.extent @_data, @value

      # method to compute the range for our color scale
      colorRange: () =>
        d3.range(9).map (i) -> "q#{i}-9"

      data: (data) =>
        @_data = data
        @redraw()

      redraw: () =>
        margin =
          top: 5
          right: 10
          bottom: 25
          left: 10

        w = @width - margin.left - margin.right
        h = @height - margin.top - margin.bottom

        quantize = d3.scale.quantize()
          .domain(@domain())
          .range(@colorRange())

        x = d3.scale.linear()
          .domain(@domain())
          .range([0, w])

        histogram =  d3.layout.histogram()
          .bins(x.ticks(10))
          .value(@value)

        data = histogram(@_data)

        y = d3.scale.linear()
          .domain([0, d3.max(data, (d)=>d.y)])
          .range([h, 0])

        xAxis = d3.svg.axis()
          .scale(x)
          .ticks(5)
          .orient("bottom")

        g = @svg.attr("width", @width)
          .attr("height", @height)
          .append("g")
          .attr("transform", "translate(#{margin.left},#{margin.top})")


        bar = g.selectAll(".bar")
          .data(data)
          .enter().append("g")
          .attr("class", "bar")
          .attr("transform", (d)=>"translate(#{x(d.x)},#{y(d.y)})")

        rect = bar.append("rect")
          .attr("x", 1)
          .attr("width", x(data[0].dx)-x(0))
          .attr("height", (d)=>(h - y(d.y)))
          .attr("class", (d)=>
            quantize(d.x)
          ).on "mouseover", (d, i)=>@_mouseover(d,i)
          .on "mouseout", (d,i)=>@_mouseout(d,i)
          .on "click", (d,i)=>@_click(d,i)

        g.append("g")
          .attr("class", "axis")
          .attr("transform", "translate(0,#{h})")
          .call(xAxis)


  .factory 'Scatter', ()->
    ###
    * Histogram
    *
    ###

    class Scatter
      constructor: (svg) ->
        @svg = d3.select(svg)
        @g = @svg.append("g")
        @g.append("g")
          .attr("class", "x-axis axis")
        @g.append("g")
          .attr("class", "y-axis axis")
        @g.append("text")
          .attr("class", "x-axis-label axis-label")
        @g.append("text")
          .attr("class", "y-axis-label axis-label")


      width: 400
      height: 400


      _mouseover: (d, i) ->
      _mouseout: (d, i) ->
      hover: (_) =>
        if _?
          [@_mouseover, @_mouseout] = _
          return this
        else
          [@_mouseover, @_mouseout]

      _click: (d, i) ->
      click: (_) =>
        if _?
          @_click = _
        else
          return @_click

      xValue: (d) => @_data[d][0]
      xDomain: () => d3.extent @_data, @value
      xLabel: ""
      yValue: (d) => @_data[d][1]
      yDomain: () => d3.extent @_data, @value
      yLabel: ""


      label: (d) => "(#{@xValue(d)},#{@yValue(d)})"

      data: (data) =>
        @_data = data
        @redraw()

      redraw: () =>
        margin =
          top: 5
          right: 5
          bottom: 50
          left: 50

        w = @width - margin.left - margin.right
        h = @height - margin.top - margin.bottom

        x = d3.scale.linear()
          .domain(@xDomain())
          .range([0, w])

        y = d3.scale.linear()
          .domain(@yDomain())
          .range([h, 0])


        xAxis = d3.svg.axis()
          .scale(x)
          .ticks(5)
          .orient("bottom")

        yAxis = d3.svg.axis()
          .scale(y)
          .ticks(5)
          .orient("left")

        @svg.attr("width", @width)
          .attr("height", @height)

        @g.attr("transform", "translate(#{margin.left},#{margin.top})")

        point = @g.selectAll(".point")
          .data(@_data)
        point.enter()
          .append("circle")
        point.exit().remove()
        point
          .attr("class", "point")
          .attr("r", 6)
          .attr "cx", (d,i)=>x(@xValue(d))
          .attr "cy", (d,i)=>y(@yValue(d))
          .on "mouseover", (d, i)=>@_mouseover(d,i)
          .on "mouseout", (d,i)=>@_mouseout(d,i)
          .on "click", (d,i)=>@_click(d,i)

        text = @g.selectAll(".label")
          .data(@_data)
        text.enter()
          .append("text")
        text.exit().remove()
        text
          .attr("class", "label")
          .attr "x", (d,i)=>x(@xValue(d)) + 5
          .attr "y", (d,i)=>y(@yValue(d) + 5)
          .text((d)=>@label(d))

        @g.select(".x-axis")
          .attr("transform", "translate(0,#{h+margin.bottom-30})")
          .call(xAxis)
        @g.select(".y-axis")
          .call(yAxis)

        @g.select(".x-axis-label")
          .text(@xLabel)
          .attr("x", w/2)
          .attr("y", h + margin.bottom - 1)
          .attr("text-anchor", "middle")
        @g.select(".y-axis-label")
          .text(@yLabel)
          .attr("transform", "rotate(-90) translate(#{-h/2}, #{- margin.left + 10})")
          .attr("text-anchor", "middle")



  .value 'calculateExtent', (dataset, prop)->
    relatedVars = dataset.getAllRelatedIndicators(prop)

    values = _(dataset.vitalsigns.keys()).map (d)->
      relatedVars.map (indicator)->dataset.getIndicatorValue(d, indicator)
    .flatten()
    .filter (v)->!isNaN(v)
    .value()
    d = d3.extent values

  .directive 'vsMap', (vsData, Choropleth, calculateExtent)->

    template: "<div><svg></svg></div>"
    restrict: 'E'
    replace: true
    scope:
      hover: "="
      click: "="
      selected: "="
      active: "="

    link: (scope, element, attr)->

      attr.$observe 'property', (prop)->
        svgNode = element.children("svg")[0]
        vsMap = new Choropleth(svgNode, "CSA_NSA_Tracts")

        vsData.then (dataset) ->
          scope.varInfo = dataset.varInfo.get(prop)

          vsMap.value = (d)->
            dataset.getIndicatorValue(d.id, prop)

          vsMap.domain = ()->calculateExtent(dataset, prop)

          vsMap.data(dataset.topojson, dataset.vitalsigns.keys())
          vsMap.hover [
            (d)-> scope.$apply ()->
              scope.hover(d.id, prop)
            (d)-> scope.$apply () ->
              scope.hover(null, null)
          ]

          vsMap.click (d)->
            scope.$apply ()->
              scope.click(d.id)

          scope.$watch "active", (newval)->
            return unless newval?
            d3.select(svgNode).selectAll(".region")
              .classed "active", (d)->
                _.contains(scope.active, d.id)
          , true

          scope.$watch "selected", (newval)->
            return unless newval?
            d3.select(svgNode).selectAll(".region")
              .classed "selected", (d)->
                _.contains(scope.selected, d.id)
          , true


  .directive 'vsHistogram', (vsData, Histogram, calculateExtent)->
    template: "<div><svg></svg></div>"
    restrict: 'E'
    replace: true
    scope:
      hover: "="
      click: "="
      selected: "="
      active: "="

    link: (scope, element, attr)->

      attr.$observe 'property', (prop)->
        svgNode = element.children("svg")[0]
        hist = new Histogram(svgNode)

        vsData.then (dataset) ->
          scope.varInfo = dataset.varInfo.get(prop)

          hist.value = (d)->
            dataset.getIndicatorValue(d, prop)

          hist.domain = ()->calculateExtent(dataset, prop)

          hist.data(dataset.vitalsigns.keys())
          hist.hover [
            (d)-> scope.$apply ()->
              scope.hover(d, prop)
            (d)-> scope.$apply () ->
              scope.hover(null, null)
          ]
          hist.click (d)->
            scope.$apply ()->
              scope.click(d)

          scope.$watch "active", (newval)->
            return unless newval?
            d3.select(svgNode).selectAll("rect")
              .classed "active", (d)->
                newval.length > 0 and _(newval).every (cid)->_(d).contains(cid)
          , true

          scope.$watch "selected", (newval)->
            return unless newval?
            d3.select(svgNode).selectAll("rect")
              .classed "selected", (d)->
                _(d).every (cid)->_(newval).contains(cid)
          , true

  .directive 'vsScatter', (vsData, Scatter, calculateExtent)->
    template: "<div><svg></svg></div>"
    restrict: 'E'
    replace: true
    scope:
      hover: "="
      click: "="
      selected: "="
      active: "="
      indicators: "="

    link: (scope, element, attr)->
      svgNode = element.children("svg")[0]
      scatter = new Scatter(svgNode)

      vsData.then (dataset) ->
        scatter.hover [
          (d)-> scope.$apply ()->
            scope.hover(d, null)
          (d)-> scope.$apply () ->
            scope.hover(null, null)
        ]
        scatter.click (d)->
          scope.$apply ()->
            scope.click(d)

        scope.$watch 'indicators', (newval)->
          return unless newval?
          [x,y] = scope.indicators

          scatter.xValue = (d)->
            dataset.getIndicatorValue(d, x)
          scatter.yValue = (d)->
            dataset.getIndicatorValue(d, y)
          scatter.xDomain = ()->calculateExtent(dataset, x)
          scatter.yDomain = ()->calculateExtent(dataset, y)

          label = (ind)->
            varInfo = dataset.varInfo.get(ind)
            varInfo["Indicator"] + "(#{varInfo['Year']})"
          scatter.xLabel = label(x)
          scatter.yLabel = label(y)

          scatter.label = (d)->d

          scatter.data(dataset.vitalsigns.keys())

          scope.$watch "active", (newval)->
            return unless newval?
            d3.select(svgNode).selectAll(".point,.label")
              .classed "active", (d)->
                newval.length > 0 and _(newval).every (cid)->_(d).contains(cid)
          , true

          scope.$watch "selected", (newval)->
            return unless newval?
            d3.select(svgNode).selectAll(".point,.label")
              .classed "selected", (d)->
                _(newval).contains(d)
          , true
        , true
