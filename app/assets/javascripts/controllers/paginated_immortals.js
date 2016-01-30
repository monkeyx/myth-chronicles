'use strict';

mythChronicles.controller('PaginatedImmortalsCtrl', ['$rootScope', '$scope', '$auth', '$state', 'actionService', 
	function($rootScope, $scope, $auth, $state, actionService){
    $scope.immortals_url = '/api/immortals';
    $scope.immortals_params = {};
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