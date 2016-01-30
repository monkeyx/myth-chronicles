'use strict';

var templates = ['alliances', 'battles', 'character_attributes', 'dashboard', 'defence', 'events',
  'home', 'immortals', 'items', 'mailbox', 'magical_equipment', 'movement', 'permissions', 'permissions_granted',
  'point_pools', 'population', 'position', 'sign_in', 'setup', 'units'];

mythChronicles.run(['$rootScope', '$state', '$templateCache', '$http', 'actionService', 'alertService','positionService','localStorageService','notificationService', 
  function($rootScope, $state, $templateCache, $http, actionService, alertService, positionService, localStorageService, notificationService) {
    for(var i = 0; i < templates.length; i++){
      // console.log('Caching template ' + templates[i]);
      $http.get('/t/' + templates[i], { cache: $templateCache });
    }

    $rootScope.$on('auth:session-expired', function() {
  		console.log('Session expired');
  		$rootScope.loggedIn = false;
      $rootScope.currentUser = null;
      alertService.clear();
      positionService.clear();
      localStorageService.clearAll();
      notificationService.clear();
      $state.transitionTo('login');
  	});
  	$rootScope.$on('auth:validation-error', function() {
  		console.log('Token validation failed');
  		$rootScope.loggedIn = false;
      $rootScope.currentUser = null;
      alertService.clear();
      positionService.clear();
      localStorageService.clearAll();
      notificationService.clear();
      $state.transitionTo('login');
  	});
  	$rootScope.$on('auth:validation-success', function(ev, user) {
  		console.log('Successful token validation');
      $rootScope.loggedIn = true;
      $rootScope.currentUser = user;
      console.log('User: ');
      console.log($rootScope.currentUser);
      alertService.clear();
      notificationService.clear();
   		if(!user.character){
        $state.transitionTo('user.setup');
      }
    });
  	$rootScope.$on('auth:login-error', function() {
  		console.log('Failed to login');
  		$rootScope.loggedIn = false;
      $rootScope.currentUser = null;
      alertService.clear();
      positionService.clear();
      localStorageService.clearAll();
      notificationService.clear();
      $state.transitionTo('login');
  	});
    $rootScope.$on('auth:invalid', function() {
      console.log('Auth invalid');
      $rootScope.loggedIn = false;
      $rootScope.currentUser = null;
      alertService.clear();
      positionService.clear();
      localStorageService.clearAll();
      notificationService.clear();
      $state.transitionTo('home');
    });
    $rootScope.$on('auth:login-success', function(ev, user) {
  		console.log('Successful login');
      $rootScope.loggedIn = true;
      $rootScope.currentUser = user;
      console.log('User: ');
      console.log($rootScope.currentUser);
      alertService.clear();
      notificationService.clear();
      if(!user.character){
        $state.transitionTo('user.setup');
      }
    });
    $rootScope.$on('auth:logout-success', function(ev) {
      console.log('Logout successful');
      $rootScope.showLoadingIndicator = false;
      $rootScope.loggedIn = false;
      $rootScope.currentUser = null;
      alertService.clear();
      positionService.clear();
      localStorageService.clearAll();
      notificationService.clear();
	    $state.transitionTo('home');
  	});
    actionService.start();
}]);