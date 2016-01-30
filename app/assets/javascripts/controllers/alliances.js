'use strict';

mythChronicles.controller('AlliancesCtrl',['$auth', '$scope', '$rootScope', '$state', 'positionService', 
	function ($auth, $scope, $rootScope, $state, positionService) {
    $scope.loadingAlliances = true;
    
    $scope.$on('pagination:loadPage', function (event, status, config) {
    	// console.log('Pagination loaded');
    	$scope.loadingAlliances = false;
    });
}]);