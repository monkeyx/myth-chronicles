'use strict';

mythChronicles.controller('PaginatedAlliancesCtrl', ['$rootScope', '$scope', '$auth', '$state', 'actionService', 
	function($rootScope, $scope, $auth, $state, actionService){
    $scope.alliances_url = '/api/alliances';
    $scope.alliances_params = {};
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