'use strict';

mythChronicles.controller('MessageLogCtrl', ['$rootScope','$scope', 'alertService', 'actionService', 
    function($rootScope, $scope, alertService, actionService){
    $scope.checked = false;
    $scope.toggle = function(){
        // console.log('Toggle Message Log');
        $scope.checked = !$scope.checked;
        $scope.alerts = alertService.get();
    }
    $rootScope.$on('myth:alert-add',function(){
        $scope.checked = true;
        $scope.alerts = alertService.get();
    });
}]);