'use strict';

mythChronicles.controller('ImmortalsCtrl',['$auth', '$scope', '$rootScope', '$state', 'positionService', 
	function ($auth, $scope, $rootScope, $state, positionService) {
    $scope.loadingImmortals = true;
    
    $scope.$on('pagination:loadPage', function (event, status, config) {
    	// console.log('Pagination loaded');
    	$scope.loadingImmortals = false;
    });
}]);