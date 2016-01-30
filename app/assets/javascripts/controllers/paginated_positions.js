'use strict';

mythChronicles.controller('PaginatedPositionsCtrl', ['$rootScope', '$scope', '$auth', '$state', 'actionService', 
	function($rootScope, $scope, $auth, $state, actionService){
    $scope.positions_url = '/api/';
    $scope.positions_params = {};
    $rootScope.$on('myth:action', function(){
        $scope.reloadPage = true;
    });

    $scope.$on('pagination:error', function (event, status, config) {
	  	if(status == 404){
	  		$state.transitionTo('user.setup');
	  	}
	  	else if(status == 403){
	  		$auth.signOut();
	  	}
	});
}]);