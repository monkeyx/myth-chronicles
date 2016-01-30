'use strict';

mythChronicles.config(['$stateProvider','$urlRouterProvider',
	function($stateProvider, $urlRouterProvider) {
  $urlRouterProvider.otherwise("/");
  $stateProvider
  .state('home', {
      url: '/',
      templateUrl: '/t/home',
      controller: 'HomeCtrl'
  })
  .state('login',{
  	url: '/sign_in',
  	templateUrl: '/t/sign_in',
  	controller: 'UserSessionsCtrl'
  })
  .state('user',{
  	url: '/u',
  	abstract: true,
  	template: '<ui-view/>',
  	resolve: {
        auth: function($auth) {
          return $auth.validateUser();
        }
      }
  })
  .state('user.setup', {
    url: '/setup',
    templateUrl: '/t/setup',
    controller: 'SetupCtrl'
  })
  .state('user.dashboard',{
  	url: '/dashboard',
  	templateUrl: '/t/dashboard',
  	controller: 'DashboardCtrl' 
  })
  .state('user.position',{
    url: '/p/:posType/:posId',
    templateUrl: '/t/position',
    controller: 'PositionCtrl'
  })
  .state('user.alliances', {
    url: '/alliances',
    templateUrl: '/t/alliances',
    controller: 'AlliancesCtrl'
  })
  .state('user.mailbox', {
    url: '/mailbox/:mailbox',
    templateUrl: '/t/mailbox',
    controller: 'MailboxCtrl'
  })
  .state('user.immortals', {
    url: '/immortals',
    templateUrl: '/t/immortals',
    controller: 'ImmortalsCtrl'
  })
  .state('user.battles', {
    url: '/battles/:battleId',
    templateUrl: '/t/battles',
    controller: 'BattlesCtrl'
  });
}]);