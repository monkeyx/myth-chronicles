'use strict';

mythChronicles.controller('BattlesCtrl', ['$rootScope','$scope', '$stateParams', '$state', '$http',
function($rootScope, $scope, $stateParams, $state, $http){
    if(!$rootScope.currentUser.character){
        $state.transitionTo('user.setup');
        return;
    }
    $scope.loadingBattles = true;
    $scope.timestamp = Date.now();
    var battleId = $stateParams.battleId;

    if(battleId && battleId != '' && battleId != 0){
        $http.get('/api/battles/' + battleId).then(function(response){
            $scope.battle = response.data;
            $scope.battle.tab = 'events';
        });
    }

    $scope.ChangeTab = function(tab){
        $scope.battle.tab = tab;
    }
    
    
    $scope.$on('pagination:loadPage', function (event, status, config) {
        // console.log('Pagination loaded');
        $scope.loadingBattles = false;
    });
}]);