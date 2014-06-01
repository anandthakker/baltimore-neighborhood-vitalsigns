angular.module('vitalsigns')
  .factory 'Selection', ()->
    class Selection
      constructor: (initString, delim)->
        @selectedValues = []
        @parse(initString, delim)

      parse: (str, delim)=>
        if str?.trim?().length > 0
          @selectedValues = str.split(delim ? ":")
      toString: (delim)=>
        (@selectedValues ? []).join(delim ? ":")


      add: (v) =>
        if !@isSelected(v)
          @selectedValues.push(v)
          @onChange()

      remove: (v) =>
        i = _.indexOf(@selectedValues, v)
        if i >= 0
          @selectedValues.splice(i,1)
          @onChange()

      toggle: (v) =>
        if @isSelected(v)
          @remove(v)
        else
          @add(v)

      isSelected: (v)=>
        _.contains(@selectedValues, v)

      ###*
      If vals is a single value, then toggle its selection.
      If vals is an array, then
        - if _any_ items are not selected, select them all.
        - if _all_ items are selected, then deselect them all.
      ###
      select: (vals) =>

        realOnChange = @onChange
        changed = false
        @onChange = ->
          changed = true

        if _.isArray(vals)
          if _.some(vals, (v)=>!@isSelected(v))
            _.map vals, @add
          else
            _.map vals, @remove
        else
          @toggle(vals)

        @onChange = realOnChange
        if changed then @onChange()


      onChange: ->
