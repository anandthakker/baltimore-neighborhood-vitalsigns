angular.module('vitalsigns')
  .factory 'parseValue', ()->
    (val)->
      val = (val ? "").replace /[$,]/, ""
      parseFloat(val)

  .factory 'Choropleth', (parseValue)->

    ###
    * d3 Map Drawing
    * (See http://bost.ocks.org/mike/map/ and
    * http://bl.ocks.org/mbostock/4060606 )
    ###

    class Choropleth
      constructor: (svg, @feature, @regionProperty) ->
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
      Property value accessor.  Uses the "id" property of each topojson
      object to look up the region's data value.
      ###
      value: (d) =>
        parseValue(@regionData.get(d.id)?.get(@regionProperty))

      # method to compute the domain for our color scale
      domain: () =>
        values = _(@regionData.values()).map (d)=>parseValue(d.get(@regionProperty))
          .filter (v)->!isNaN(v)
          .value()
        d = d3.extent values


      # method to compute the range for our color scale
      colorRange: () =>
        d3.range(9).map (i) -> "q#{i}-9"

      data: (mapdata, regiondata) =>
        @topojsonData = mapdata
        @regionData = regiondata
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


  .factory 'Histogram', (parseValue)->
    ###
    * Histogram
    *
    ###

    class Histogram
      constructor: (svg, @regionProperty) ->
        @svg = d3.select(svg)

      width: 200
      height: 100

      value: (d) =>
        parseValue(d.get(@regionProperty))

      # method to compute the domain
      domain: () =>
        d3.extent @regionData.values(), @value

      # method to compute the range for our color scale
      colorRange: () =>
        d3.range(9).map (i) -> "q#{i}-9"

      data: (regiondata) =>
        @regionData = regiondata
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

        data = histogram(@regionData.values())

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
          )

        g.append("g")
          .attr("class", "axis")
          .attr("transform", "translate(0,#{h})")
          .call(xAxis)


  .directive 'vsMap', (vsData, Choropleth)->

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
        vsMap = new Choropleth(svgNode, "CSA_NSA_Tracts", prop)

        vsData.then (dataset) ->
          scope.varInfo = dataset.varInfo.get(prop)
          vsMap.data(dataset.topojson, dataset.vitalsigns)
          vsMap.hover [
            (d)-> scope.$apply ()->
              scope.hover(d.id, prop)
            (d)->
          ]

          vsMap.click (d)->
            scope.$apply ()->
              scope.click(d.id)

          scope.$watch "active", (newval)->
            return unless newval?
            d3.select(svgNode).selectAll(".region")
              .classed "active", (d)-> d.id is scope.active

          scope.$watch "selected", (newval)->
            return unless newval?
            console.log newval
            d3.select(svgNode).selectAll(".region")
              .classed "selected", (d)->
                _.contains(scope.selected, d.id)
          , true


  .directive 'vsHistogram', (vsData, Histogram)->
    template: "<div><svg></svg></div>"
    restrict: 'E'
    replace: true
    scope:
      hover: "="

    link: (scope, element, attr)->
      attr.$observe 'property', (prop)->
        svgNode = element.children("svg")[0]
        hist = new Histogram(svgNode, prop)

        vsData.then (dataset) ->
          scope.varInfo = dataset.varInfo.get(prop)
          hist.data(dataset.vitalsigns)
