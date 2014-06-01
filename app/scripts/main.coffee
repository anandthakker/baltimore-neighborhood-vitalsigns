
angular.module 'vitalsigns', ['ui.router']

  .config ($stateProvider, $urlRouterProvider)->

    $stateProvider
      .state 'main',
        url: "/i/:indicators"
        abstract: true
        templateUrl: "partials/main.tpl.html"
        controller: "main"
        resolve:
          indicatorSelection: ($location, $rootScope, $stateParams, Selection)->
            selection = new Selection($stateParams.indicators)
            selection.onChange = ()->
              $rootScope.skipStateChange = true
              current = $location.path()
              $location.path(current.replace /\/i\/.*\//, "/i/#{@toString()}/")
            selection

          dataset: "vsData"

      .state 'main.multiples',
        url: "/"
        views:
          'controls':
            templateUrl: "partials/controls.tpl.html"
          'multiples':
            templateUrl: "partials/multiples.tpl.html"
          'comments':
            # templateUrl: "partials/comments.tpl.html"
            template: ""

    $urlRouterProvider.otherwise "/i//"

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

  .controller 'main', ($scope, dataset, indicatorSelection, $location, $state, $stateParams)->
    $scope.vitalsigns = dataset.vitalsigns
    $scope.varInfo = dataset.varInfo

    # For "controls" (the list of indicators to choose from)
    $scope.indicators = _(dataset.varInfo.values())
    .filter (varInfo)->
      _.contains dataset.variables, varInfo["Variable Name"]
    .groupBy 'Section'
    .value()

    $scope.selection = indicatorSelection


    $scope.selectCommunity = (cid, indicator) ->
      $scope.currentCommunity = cid
      $scope.currentIndicator = indicator

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
