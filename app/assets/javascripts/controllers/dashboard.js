'use strict';

mythChronicles.controller('DashboardCtrl',['$auth', '$scope', '$rootScope', '$state', 'positionService', 
	function ($auth, $scope, $rootScope, $state, positionService) {
    // console.log('DashboardCtrl');
    $scope.loadingPositions = true;
    $scope.timestamp = Date.now();
    
    $scope.$on('pagination:loadPage', function (event, status, config) {
    	// console.log('Pagination loaded');
    	$scope.loadingPositions = false;
    });

    if($rootScope.currentUser){
        // console.log($rootScope.currentUser);
        if($rootScope.currentUser.character){
            positionService.game();
        }else {
            $state.transitionTo('user.setup');
        }
    }else {
        $state.transitionTo('home');
    }
}]);