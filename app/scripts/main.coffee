
angular.module 'vitalsigns', ['ui.router']

  .config ($stateProvider, $urlRouterProvider)->

    $stateProvider
      .state 'main',
        url: "/i/:indicators"
        abstract: true
        templateUrl: "partials/main.tpl.html"
        controller: "main"
        resolve:
          indicatorSelection: ($stateParams, Selection)->
            selection = new Selection($stateParams.indicators)
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


  .run ($rootScope) ->
    $rootScope._ = _

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
    indicatorSelection.onChange = ()->
      current = $location.path()
      $location.path(current.replace /\/i\/.*\//, "/i/#{@toString()}/")


    $scope.selectCommunity = (cid, indicator) ->
      $scope.currentCommunity = cid
      $scope.currentIndicator = indicator

    $scope.moveLeft = (v)->
      i = _.indexOf($scope.selection.selectedValues, v)
      tmp = $scope.selection.selectedValues[i]
      $scope.selection.selectedValues[i]=$scope.selection.selectedValues[i-1]
      $scope.selection.selectedValues[i-1] = tmp
      $state.go('main.multiples',{indicators: $scope.selection.toString()})

    $scope.moveRight = (v)->
      i = _.indexOf($scope.selection.selectedValues, v)
      tmp = $scope.selection.selectedValues[i]
      $scope.selection.selectedValues[i]=$scope.selection.selectedValues[i+1]
      $scope.selection.selectedValues[i+1] = tmp
      $state.go('main.multiples',{indicators: $scope.selection.toString()})
