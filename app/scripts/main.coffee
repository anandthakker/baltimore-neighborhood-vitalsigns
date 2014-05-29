
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


  .factory 'choropleth', (vsData)->

    ###
    * d3 Map Drawing
    * (See http://bost.ocks.org/mike/map/ and
    * http://bl.ocks.org/mbostock/4060606 )
    ###

    width = 200;
    height = 200;

    projection = d3.geo.mercator()
    projection.scale(50000)
    projection.center([-76.6167, 39.2833])
    projection.translate([width/2, height/2])

    path = d3.geo.path().projection(projection)

    choropleth = (svg, vsProp)->
      svg = d3.select(svg)
      vsData.then (dataset)->
        mapdata = dataset.topojson
        vitalsigns = dataset.vitalsigns
        # Todo: get this hardcoded property name out of here.
        feature = mapdata.objects["CSA_NSA_Tracts"]

        val = (d)->
          parseFloat(d.get(vsProp))
        domain = [
          d3.min vitalsigns.values(), val
          d3.max vitalsigns.values(), val
        ]

        quantize = d3.scale.quantize()
          .domain(domain)
          .range(d3.range(9).map( (i) -> ("q" + i + "-9") ) )

        svg.attr("width", width)
          .attr("height", height)
          .attr("data-property", vsProp)
          .attr("data-min", domain[0])
          .attr("data-max", domain[1])

        val = (d)->
          parseFloat(vitalsigns.get(d.id)?.get(vsProp)) ? 0

        svg.selectAll(".community")
          .data(topojson.feature(mapdata, feature).features)
          .enter()
          .append("path")
          .attr("data-community", (d)->d.id)
          .attr("data-property", val)
          .attr("class", (d)->
            quantize(val(d))
          )
          .attr("d", path)

        svg.append("path")
          .datum(topojson.mesh(mapdata, feature))
          .attr("d", path)
          .attr("class", "community-boundary");

      , (reason) ->
        console.error(reason)


  .directive 'vsMap', (vsData, choropleth)->
    templateUrl: "partials/vs-map.tpl.html"
    restrict: 'E'
    replace: true
    link: (scope, element, attr)->
      attr.$observe 'property', (prop)->
        vsData.then (dataset) ->
          choropleth(element.children("svg")[0], prop)
          scope.varInfo = dataset.varInfo.get(prop)


  .factory 'Selection', ()->
    class Selection
      constructor: ()->

      selectedValues: []

      add: (v) =>
        if !@isSelected(v) then @selectedValues.push(v)

      remove: (v) =>
        console.log "Removing v"
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
      $scope.vars = dataset.variables

      liveVars = _.filter(dataset.varInfo.values(), (varInfo)->
        _.contains dataset.variables, varInfo["Variable Name"]
      )
      $scope.indicators = _.groupBy liveVars, 'Section'

      $scope.selection = new Selection()
