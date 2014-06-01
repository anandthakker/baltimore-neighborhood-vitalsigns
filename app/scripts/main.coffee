
angular.module 'vitalsigns', ['ui.router']

  .config ($stateProvider, $urlRouterProvider)->

    $stateProvider
      .state 'main',
        url: "/i/:indicators/c/:communities"
        abstract: true
        templateUrl: "partials/main.tpl.html"
        resolve:
          indicatorSelection: ["$location", "$rootScope", "$stateParams", "Selection",($location, $rootScope, $stateParams, Selection)->
            selection = new Selection($stateParams.indicators)
            selection.onChange = ()->
              $rootScope.skipStateChange = true
              current = $location.path()
              updated = current.replace /\/i\/[^\/]*\//, "/i/#{@toString()}/"
              $location.path(updated)
            selection
          ]

          communitySelection: ["$location", "$rootScope", "$stateParams", "Selection",($location, $rootScope, $stateParams, Selection)->
            esc = (s)->
              s.replace /-/g, "-~"
                .replace /\//g, "--"
                .replace /\s/g, "-_"
            unesc = (s)->
              s.replace /-_/g, " "
                .replace /--/g, "/"
                .replace /-~/g, "-"

            selection = new Selection(unesc($stateParams.communities))
            selection.onChange = ()->
              $rootScope.skipStateChange = true
              current = $location.path()
              updated = current.replace /\/c\/[^\/]*\//, "/c/#{esc(@toString())}/"
              $location.path(updated)
            selection
          ]

          dataset: "vsData"

      .state 'main.multiples',
        url: "/"
        views:
          'controls':
            templateUrl: "partials/controls.tpl.html"
            controller: "controls"
          'multiples':
            templateUrl: "partials/multiples.tpl.html"
            controller: "multiples"

          'comments':
            # templateUrl: "partials/comments.tpl.html"
            template: ""

    $urlRouterProvider.otherwise "/i//c//"

    #allows us to prevent url changes from firing state transitions
    # (see run())
    $urlRouterProvider.deferIntercept()


  .run ($rootScope, $urlRouter) ->
    $rootScope._ = _

    $rootScope.$on '$locationChangeSuccess', (e) ->
      if $rootScope.skipStateChange
        $rootScope.skipStateChange = false
        e.preventDefault()

    #Configures $urlRouter's listener *after* your custom listener
    $urlRouter.listen();

  .controller "controls", ($scope, dataset, indicatorSelection)->
    $scope.varInfo = dataset.varInfo

    $scope.indicators = _(dataset.varInfo.values())
    .filter (varInfo)->
      _.contains dataset.variables, varInfo["Variable Name"]
    .groupBy 'Section'
    .value()

    $scope.clear = ()->indicatorSelection.clear()
    $scope.isSelected = (v)->indicatorSelection.isSelected(v["Variable Name"])
    $scope.select = (v)->indicatorSelection.select(
      if _.isArray(v)
        _.pluck(variables, 'Variable Name')
      else
        v["Variable Name"]
    )

    lastDragSelect = null
    $scope.startDragSelect = (v)->
      $scope.select(v)
      if($scope.isSelected(v))
        lastDragSelect = v

    $scope.endDragSelect = ()->
      lastDragSelect = null

    $scope.dragSelect = (section, v)->
      if(lastDragSelect?)
        m = 1 + _($scope.indicators[section]).indexOf lastDragSelect
        n = _($scope.indicators[section]).indexOf v
        for i in [m..n]
          indicatorSelection.add($scope.indicators[section][i]["Variable Name"])


  .controller 'multiples', ($scope, dataset, indicatorSelection, communitySelection)->
    $scope.vitalsigns = dataset.vitalsigns
    $scope.varInfo = dataset.varInfo


    $scope.selection = indicatorSelection
    $scope.communitySelection = communitySelection

    $scope.selectCommunity = (cid)->
      $scope.communitySelection.select(cid)

    $scope.showCommunity = (cid, indicator) ->
      $scope.currentCommunity = cid
      $scope.currentIndicator = indicator
      $scope.activeCommunities = [cid]

    $scope.selectCommunities = (cid)->
      $scope.communitySelection.select(cid)
      $scope.activeCommunities = []

    $scope.showCommunities = (cid, indicator) ->
      if(cid.length is 1)
        $scope.currentCommunity = cid[0]
      else
        $scope.currentCommunity = null
      $scope.currentIndicator = indicator
      $scope.activeCommunities = cid


    $scope.moveLeft = (v)->
      i = _.indexOf($scope.selection.selectedValues, v)
      tmp = $scope.selection.selectedValues[i]
      indicatorSelection.selectedValues[i]=$scope.selection.selectedValues[i-1]
      indicatorSelection.selectedValues[i-1] = tmp
      indicatorSelection.onChange()

    $scope.moveRight = (v)->
      i = _.indexOf($scope.selection.selectedValues, v)
      tmp = $scope.selection.selectedValues[i]
      indicatorSelection.selectedValues[i]=$scope.selection.selectedValues[i+1]
      indicatorSelection.selectedValues[i+1] = tmp
      indicatorSelection.onChange()
