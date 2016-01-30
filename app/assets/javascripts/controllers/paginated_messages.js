'use strict';

mythChronicles.controller('PaginatedMessagesCtrl', ['$rootScope', '$scope', '$auth', '$state', 'actionService', 
	function($rootScope, $scope, $auth, $state, actionService){
    $scope.messages_url = '/api/messages';
    $scope.messages_params = {mailbox: $rootScope.mailbox};
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