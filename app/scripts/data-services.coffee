angular.module 'vitalsigns'
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


    ###
    Topojson data
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


    ###
    BNIA Indicator data
    ###
    read_csv = (d)->
      id = d["CSA2010"]
      return if id is "Baltimore City"
      if not vsData.vitalsigns.has(id)
        vsData.vitalsigns.set(id, d3.map())

      for property, value of d
        vsData.vitalsigns.get(id).set(property, value) unless property is "CSA2010"

      return d

    done = (error, rows) ->
      if error then throw new Error(error)
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
