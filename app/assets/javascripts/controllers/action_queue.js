'use strict';

mythChronicles.controller('ActionQueueCtrl', ['$scope', '$rootScope', 'actionService', 
function($scope, $rootScope, actionService){
    $scope.checked = false;
    $scope.toggle = function(){
        // console.log('Toggle Action Queue');
        $scope.checked = !$scope.checked;
    }
    $scope.actionCount = actionService.count();
    $scope.queuedActions = actionService.list();
    $scope.cancelAction = function(actionName){
        actionService.cancel(actionName);
    };
    $rootScope.$on('myth:action', function(){
        $scope.queuedActions = actionService.list();
        $scope.actionCount = actionService.count();
    });
    $rootScope.$on('auth:logout-success', function(ev) {
      $scope.actionCount = 0;
      $scope.queuedActions = [];
      $scope.checked = false;
    });
}]);