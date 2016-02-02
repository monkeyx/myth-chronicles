'use strict';

mythChronicles.controller('HomeCtrl',['$rootScope', '$state', function ($rootScope, $state) {
    // console.log('HomeCtrl');
	if(!$rootScope.notLoggedIn){
        // console.log('Logged In');
        if($rootScope.currentUser.character){
        	$state.transitionTo('user.dashboard');
        } else {
        	$state.transitionTo('user.setup');
        }
    } else {
        // console.log('Not logged in');
    }
}]);