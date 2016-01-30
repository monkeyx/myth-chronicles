'use strict';

mythChronicles.controller('PositionCtrl',['$auth', '$rootScope', '$scope', '$state', '$stateParams', '$filter', '$uibModal', 'actionService', 'positionService', 'notificationService',
    function ($auth, $rootScope, $scope, $state, $stateParams, $filter, $uibModal, actionService, positionService, notificationService) {
    // console.log('PositionCtrl');
    if(!$rootScope.currentUser.character){
        $state.transitionTo('user.setup');
        return;
    }
    var posType = $stateParams.posType;
    var posId = $stateParams.posId;
    $scope.action = null;
    $scope.waitingForMap = false;
    $scope.position = null;

    $scope.hide_events_table = false;
    $scope.toggleEventsTable = function(){
        $scope.hide_events_table = !$scope.hide_events_table;
    };

    $scope.hide_items_table = false;
    $scope.toggleItemsTable = function(){
        $scope.hide_items_table = !$scope.hide_items_table;
    };

    $scope.hide_quests_table = false;
    $scope.toggleQuestsTable = function(){
        $scope.hide_quests_table = !$scope.hide_quests_table;
    };

    // console.log('Type: ' + posType + ' Id: ' + posId);

    notificationService.start(posType, posId);

    positionService.position(posType, posId).then(function(position){
        $scope.position = position;
        $scope.position.defenceUpgradeCost = (position.defence_rating + 1) * (position.defence_rating + 1) * 50;
    });

    try{
        $rootScope.offActionSuccessWatch();
        $rootScope.offActionSuccessWatch = null;
    }catch(err){}
        
    try{
        $rootScope.mapHiddenWatch();
        $rootScope.offActionSuccessWatch = null;
    }catch(err){}

    $rootScope.offActionSuccessWatch = $rootScope.$on('myth:action-success', function(){
        positionService.clear();
        positionService.position(posType, posId).then(function(position){
            $scope.position = position;
            $scope.position.defenceUpgradeCost = (position.defence_rating + 1) * (position.defence_rating + 1) * 50;
        });
    });

    $rootScope.mapHiddenWatch = $rootScope.$on('myth:mapHidden', function(event, args) {
        console.log('Received map hidden (waiting? ' + $rootScope.waitingForMap + ')');
        if($rootScope.waitingForMap){
            $rootScope.waitingForMap = false;
            if($scope.action){
                $scope.showActionForm($scope.action.name, true);
            }
        }
    });

    $scope.showButton = function(actionName){
        return $scope.position && $scope.position.actionMap && $scope.position.actionMap.hasOwnProperty(actionName);
    };

    $scope.showHover = function(actionName){
        return $scope.position && $scope.position.actionMap && $scope.position.actionMap.hasOwnProperty(actionName) &&
         $scope.position.actionMap[actionName] && $scope.position.actionMap[actionName].hasOwnProperty('showHover') &&
          $scope.position.actionMap[actionName].showHover;
    };

    $scope.overActionButton = function(actionName){
        if($scope.position && $scope.position.actionMap && $scope.position.actionMap.hasOwnProperty(actionName) &&
         $scope.position.actionMap[actionName]){
            $scope.position.actionMap[actionName].showHover = true;
        }
    };

    $scope.leaveActionButton = function(actionName){
        if($scope.position && $scope.position.actionMap && $scope.position.actionMap.hasOwnProperty(actionName) &&
         $scope.position.actionMap[actionName]){
            $scope.position.actionMap[actionName].showHover = false;
        }
    };

    $scope.showActionForm = function(actionName, keepValues){
        $scope.action = null;
        $scope.action = $filter('filter')($scope.position.actions, {name: actionName}, true)[0];
        if($scope.action != null){
            $scope.action.keepValues = keepValues;
            OpenActionForm();
        }
    };

    function OpenActionForm(){
        var modalInstance = $uibModal.open({
            animation: true,
            templateUrl: 'actionForm.html',
            controller: 'ActionFormCtrl',
            resolve: {
                action: function(){
                    return $scope.action;
                },
                position: function(){
                    return $scope.position;
                }
            }
        });
        modalInstance.result.then(function(action){
            $scope.action = action;
        });
    }
}]);