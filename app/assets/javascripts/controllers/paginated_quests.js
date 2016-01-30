'use strict';

mythChronicles.controller('PaginatedQuestsCtrl', ['$rootScope', '$scope', '$auth', '$state', 'actionService', 'positionService',
    function($rootScope, $scope, $auth, $state, actionService, positionService){
        $scope.quests_url = '/api/quests';
        $scope.quests_params = {};
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