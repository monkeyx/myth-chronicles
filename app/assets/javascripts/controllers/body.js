'use strict';

mythChronicles.controller('BodyCtrl', ['$rootScope','$scope','positionService', 
function($rootScope, $scope, positionService){
    $rootScope.showLoadingIndicator = false;
    GetPositions();
    $rootScope.$on('$locationChangeSuccess', function(){
        $scope.isCollapsed = true;
    });
    $rootScope.$on('auth:logout-success', function(ev) {
        $scope.isCollapsed = true;
        $scope.game = null;
    	$scope.character = null;
    	$scope.armies = null;
    	$scope.settlements = null;
    });
    $rootScope.$on('auth:login-success', function(ev, user) {
    	GetPositions();
    });
    $rootScope.$on('myth:action-success', function(ev, user) {
        GetPositions();
    });
    $rootScope.$on('myth:notification', function(ev, user) {
        GetPositions();
    });
    $rootScope.$watch('currentUser', function(){
        GetPositions();;
    });

    $scope.showAlert = true;
    $scope.showNotice = true;

    $scope.hideAlert = function(){
        $scope.showAlert = false;
    };

    $scope.hideNotice = function(){
        $scope.showNotice = false;
    };

    function GetPositions(){
        if(!($rootScope.currentUser && $rootScope.currentUser.character)){
            return;
        }
        $scope.isCollapsed = true;
        // console.log('BodyCtrl - Get Positions');
        positionService.clear();
        positionService.game().then(function(game){
            $scope.game = game;
        });
    	positionService.character().then(function(character){
	    	$scope.character = character;
	    });
	    positionService.armies().then(function(armies){
	    	$scope.armies = armies;
	    });
	    positionService.settlements().then(function(settlements){
	    	$scope.settlements = settlements;
	    });
    }
}]);