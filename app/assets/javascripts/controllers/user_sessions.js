'use strict';

mythChronicles.controller('UserSessionsCtrl', ['$scope', '$rootScope', '$state', 'positionService', 
    function ($scope, $rootScope, $state, positionService) {
    // console.log('UserSessionsCtrl');
    $scope.$on('auth:login-error', function(ev, reason) {
        $scope.error = reason.errors[0];
        $rootScope.currentUser = null;
        $rootScope.loggedIn = false;
    });
    $scope.$on('auth:login-success', function(ev, user){
        $rootScope.currentUser = user;
        $rootScope.loggedIn = true;
        positionService.character();
        $state.transitionTo('user.dashboard');
    });
}]);