
angular.module 'vitalsigns', []
  .run ($rootScope) ->
    $rootScope._ = _

  .factory 'vsData', ($q)->

    deferred = $q.defer()

    vsData =
      topojson: null
      codebook: null
      vitalsigns: d3.map()
      variables: []
      varInfo: d3.map()

    ###
    * Read data
    *
    * The "id" feature in the topojson ("Community" from the original shapefile) is
    * equivalent to the "CSA2010" column in the vital signs datasets.
    ###

    d3.json "data/csa_2010_boundaries/CSA_NSA_Tracts.topo.json", (error, boundaries) ->
      if (error)
        deferred.reject(error)
        throw new Error(error)

      vsData.topojson = boundaries

      d3.csv "data/Vital Signs Codebook and Sources - Variables and Sources.csv",
        (d)->d,
        (error, rows)->
          if (error)
            deferred.reject(error)
            throw new Error(error)

          vsData.codebook = rows

          for v in vsData.codebook
            varname = v['Variable Name']
            varname = varname.substring(0, varname.length - 2)
            yrs = (year for year in [2007..2013])

            pad = (a,b) -> (1e15+a+"").slice(-b)
            for year in yrs
              yr = pad(year - 2000, 2)
              newV = angular.extend({Year: year},v)
              newV['Variable Name'] = varname + yr
              vsData.varInfo.set(varname + yr, newV)


          deferred.resolve(vsData)


    read_csv = (d)->
      id = d["CSA2010"]
      if not vsData.vitalsigns.has(id)
        vsData.vitalsigns.set(id, d3.map())

      for property, value of d
        vsData.vitalsigns.get(id).set(property, value) unless property is "CSA2010"

      return d

    done = (error, rows) ->
      for prop, val of rows[0]
        vsData.variables.push prop unless prop is "CSA2010"

    d3.csv "data/VS Arts 2011-2012 - VS Arts 2010-2012.csv", read_csv, done
    d3.csv "data/VS Census 2010-2012 - VS Census 2010-2012.csv", read_csv, done
    d3.csv "data/VS Crime 2010-2012 - VS Crime 2010-2012.csv", read_csv, done
    d3.csv "data/VS Education 2010-2012 - VS Education 2010-2012.csv", read_csv, done
    d3.csv "data/VS Health 2010-2012 - VS_Health_2010-2012.csv", read_csv, done
    d3.csv "data/VS Housing 2010-2012 - VS Housing 2010-2012.csv", read_csv, done
    d3.csv "data/VS Sustainability 2010-2012 - VS Sustainability 2010-2012.csv", read_csv, done
    d3.csv "data/VS Workforce 2010-2012 - VS Workforce 2010-2012.csv", read_csv, done

    deferred.promise


  .factory 'Choropleth', (vsData)->

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

      # parse numerical data from strings
      # TODO: handle dollar signs, commas, etc.
      parseValue: (val)->
        parseFloat(val)

      ###
      Property value accessor.  Uses the "id" property of each topojson
      object to look up the region's data value.
      ###
      value: (d) =>
        @parseValue(@regionData.get(d.id)?.get(@regionProperty))

      # method to compute the domain for our color scale
      domain: () =>
        d3.extent @regionData.values(), (d)=>@parseValue(d.get(@regionProperty))

      # method to compute the range for our color scale
      range: () =>
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
          .range(@range())

        @svg.attr("width", @width)
          .attr("height", @height)

        @svg.selectAll(".region")
          .data(topojson.feature(@topojsonData, feature).features)
          .enter()
          .append("path")
          .attr("d", @path)
          .attr("data-region", (d)->d.id)
          .attr("class", (d)=>
            quantize(@value(d))
          ).on "mouseover", (d, i)=>@_mouseover(d,i)
          .on "mouseout", (d,i)=>@_mouseout(d,i)

        @svg.append("path")
          .datum(topojson.mesh(@topojsonData, feature))
          .attr("d", @path)
          .attr("class", "region-boundary");


  .directive 'vsMap', (vsData, Choropleth)->
    templateUrl: "partials/vs-map.tpl.html"
    restrict: 'E'
    replace: true
    scope:
      hover: "="

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


  .factory 'Selection', ()->
    class Selection
      constructor: ()->

      selectedValues: []

      add: (v) =>
        if !@isSelected(v) then @selectedValues.push(v)

      remove: (v) =>
        i = _.indexOf(@selectedValues, v)
        if i >= 0 then @selectedValues.splice(i,1)

      toggle: (v) =>
        if @isSelected(v)
          @remove(v)
        else
          @add(v)

      isSelected: (v)=>
        _.contains(@selectedValues, v)

      select: (vals) =>
        if _.isArray(vals)
          if _.some(vals, (v)=>!@isSelected(v))
            _.map vals, @add
          else
            _.map vals, @remove
          return
        else
          @toggle(vals)


  .controller 'main', ($scope, vsData, Selection)->

    vsData.then (dataset)->
      $scope.vitalsigns = dataset.vitalsigns
      $scope.vars = dataset.variables

      liveVars = _.filter(dataset.varInfo.values(), (varInfo)->
        _.contains dataset.variables, varInfo["Variable Name"]
      )
      $scope.indicators = _.groupBy liveVars, 'Section'

      $scope.selection = new Selection()

      $scope.selectCommunity = (cid, indicator) ->
        $scope.currentCommunity = cid
        $scope.currentIndicator = indicator
        $scope.currentCommunityData = dataset.vitalsigns.get(cid)
        $scope.currentIndicatorInfo = dataset.varInfo.get(indicator)
