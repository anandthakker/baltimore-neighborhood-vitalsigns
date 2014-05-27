
width = 960;
height = 1160;

svg = d3.select("body").append("svg")
  .attr("width", width)
  .attr("height", height)


projection = d3.geo.mercator()
projection.scale(50000)
projection.center([-76.6, 39.2])

quantize = d3.scale.quantize()
  .domain([0, 500])
  .range(d3.range(9).map( (i) -> ("q" + i + "-9") ) )

d3.json "data/vitalsigns.json", (error, crime) ->
  if (error) then return console.error(error)
  svg.selectAll(".community")
    .data(topojson.feature(crime, crime.objects["VS_Crime_2010-2012"]).features)
    .enter()
    .append("path")
    .attr("data-community", (d)->d.id)
    .attr("class", (d)->
      console.log d
      "community " + quantize(d.properties.crime10)
    )
    .attr("d", d3.geo.path().projection(projection))
