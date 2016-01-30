'use strict';

mythChronicles.controller('PaginatedEventsCtrl', ['$rootScope', '$scope', '$auth', '$state', 'actionService', 'positionService',
    function($rootScope, $scope, $auth, $state, actionService, positionService){
        positionService.lastPosition().then(function(position){
            $scope.events_url = '/api/' + position.type + '/' + position.id + '/events';
            $scope.event_params = {};
            $rootScope.$on('myth:action', function(){
                $scope.reloadPage = true;
            });
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