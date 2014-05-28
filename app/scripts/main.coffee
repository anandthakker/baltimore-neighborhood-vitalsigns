
vitalsigns = d3.map()
vsProps = d3.map()

###
* d3 Map Drawing
* (See http://bost.ocks.org/mike/map/)
###

width = 200;
height = 200;

projection = d3.geo.mercator()
projection.scale(50000)
projection.center([-76.6167, 39.2833])
projection.translate([width/2, height/2])

path = d3.geo.path().projection(projection)

chloropleth = (mapdata, feature, vsProp)->

  svg = d3.select("body").append("svg")
    .attr("width", width)
    .attr("height", height)

  extent = d3.extent vitalsigns.values(), (d)->
    d.get(vsProp)

  quantize = d3.scale.quantize()
    .domain(extent)
    .range(d3.range(9).map( (i) -> ("q" + i + "-9") ) )

  val = (d)->
    vitalsigns.get(d.id)?.get(vsProp) ? 0

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


###
* Read data
* First grab the topojson file, then (in parallel) grab each of the vital signs
* datasets.
*
* The "id" feature in the topojson ("Community" from the original shapefile) is
* equivalent to the "CSA2010" column in the vital signs datasets.
*
###

d3.json "data/csa_2010_boundaries/CSA_NSA_Tracts.topo.json", (error, boundaries) ->

  read_csv = (category) ->
    propList = d3.set()
    vsProps.set(category, propList)
    (d)->
      id = d["CSA2010"]

      if not vitalsigns.has(id)
        vitalsigns.set(id, d3.map())

      community = vitalsigns.get(id)

      for property, value of d
        unless property is "CSA2010"
          community.set(property, value)
          propList.add(property)


  drawMaps = (category) -> (rows) ->
    for prop in vsProps.get(category).values()
      chloropleth(boundaries, boundaries.objects["CSA_NSA_Tracts"], prop)

  if (error) then return console.error(error)
  queue()
    .defer d3.csv, "data/VS Arts 2011-2012 - VS Arts 2010-2012.csv", read_csv("Arts"), drawMaps("Arts")
    .defer d3.csv, "data/VS Census 2010-2012 - VS Census 2010-2012.csv", read_csv("Census"), drawMaps("Census")
    .defer d3.csv, "data/VS Crime 2010-2012 - VS Crime 2010-2012.csv", read_csv("Crime"), drawMaps("Crime")
    .defer d3.csv, "data/VS Education 2010-2012 - VS Education 2010-2012.csv", read_csv("Education"), drawMaps("Education")
    .defer d3.csv, "data/VS Health 2010-2012 - VS_Health_2010-2012.csv", read_csv("Health"), drawMaps("Health")
    # .defer d3.csv, "data/VS Housing 2010-2012 - VS Housing 2010-2012.csv", read_csv("Housing"), drawMaps("Housing")
    # .defer d3.csv, "data/VS Sustainability 2010-2012 - VS Sustainability 2010-2012.csv", read_csv("Sustainability"), drawMaps("Sustainability")
    # .defer d3.csv, "data/VS Workforce 2010-2012 - VS Workforce 2010-2012.csv", read_csv("Workforce"), drawMaps("Workforce")
    .await ->
