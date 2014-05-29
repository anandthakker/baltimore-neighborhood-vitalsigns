# Baltimore Neighborhood Vital Signs

Playing around with [BNIA][1] data for [Hack Baltimore][2], in the form of a
basic [AngularJS][4] and [d3js][5]-powered webapp.

[1]:[http://bniajfi.org/vital_signs/data_downloads/]
[2]:[http://hackbaltimore.org/events/hack-for-change-baltimore/]
[4]:[http://angularjs.org]
[5]:[http://d3js.org]

## Start!

    npm install
    bower install
    gulp watch

Then go to <http://localhost:9000>, and start hacking in `app/`.

## Data

The data in `app/data` is all originally from [BNIA][1]. Here's what's there:

- `csa_2010_boundaries/`
  - `CSA_NSA_Tracts.shp`,`.prj`,`.sbn`,`.sbx`,`.shx`: Baltimore communities shapefile and related files from BNIA
  - `CSA_NSA_Tracts.json`: GeoJSON file generated from shapefiles using `ogr2ogr`.
  - `CSA_NSA_Tracts.topo.json`: TopoJSON file generated from the GeoJSON, with some simplification to make rendering faster when it's used by `d3`.

The feature in the topojson is called `CSA_NSA_Tracts`.

- `Vital Signs Codebook and Sources - Variables and Sources.csv`: metadata about each indicator variable in the dataset, including how to variable names like `"tpopXX"` into `"Total Population"`
- `VS XXXX 2010-2012 - VS XXXX 2010-2012.csv`: community data about section `XXXX` (Arts, Census, Crime, Education, Health, Housing, Sustainability, Workforce).

To correlate data across these files:

`Community` from shapefiles = `id` in topojson = `CSA2010` in the `VS*.csv` data.

See Mike Bostock's [d3 mapping tutorial][3] for more on using `ogr2ogr` and `topojson`.

[3]:[http://bost.ocks.org/mike/map/]

## Angular module

<app/scripts/main.coffee> defines the Angular module `vitalsigns`, which includes the following.
(Note that there's a dependency on [lodash][6].)

[6]:[http://lodash.com]

### Data service `vsData`

A promise to an object with the following properties:

- `topojson`: topojson of community regions
- `codebook`: array of variable descriptions, one for each indicator in the dataset (from [Vital Signs Codebook and Sources - Variables and Sources.csv](app/data/Vital Signs Codebook and Sources - Variables and Sources.csv))
- `vitalsigns`: a [`d3.map()`][7] from community id to _another_ map
- `variables`: an array of variables that have been loaded from the `csv` data.
- `varInfo`: a [`d3.map()`][7] from variable to variable info (more useful than `codebook`).

Note that in `codebook` the variable names are suffixed with `"XX"`, as it's a direct
translation of the codebook CSV file, whereas in `variables` and `varInfo`, the suffixes are
specific years, as in the actual community data files (e.g., `"pwhite10"`).

### Directive `vs-map`

    <vs-map property="teenbir10">

Directive for creating a choropleth for the given indicator variable. Note that this depends on the styles in [_maps.scss](app/styles/_maps.scss).

(It would be nice if this took some parameters, at the very least for
sizing the `svg`.)


[7]: [https://github.com/mbostock/d3/wiki/Arrays#maps]



## Deploying

I'll let you know once I've done it :)

## License

Read [LICENSE](LICENSE).
