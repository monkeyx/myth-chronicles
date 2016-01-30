'use strict';

mythChronicles.controller('ActionFormCtrl', ['$rootScope', '$scope', '$uibModalInstance', 'actionService', 'position', 'action',
function($rootScope, $scope, $uibModalInstance, actionService, position, action){
    // console.log('** SHOW ACTION FORM **');
    // console.log(' Position: ');
    // console.log(position);
    // console.log(' Action: ');
    // console.log(action);
    $scope.error = null;
    $scope.errors = {};
    $scope.action = action;
    $scope.position = position;
    $rootScope.$on('$locationChangeSuccess', function(){
        $uibModalInstance.dismiss('cancel');
    });
    $rootScope.$on('myth:mapShown', function(event, args) {
        $uibModalInstance.dismiss('cancel');
    });

    for(var i = 0; i < $scope.action.params.length; i++){
        var paramName = $scope.action.params[i].name;
        if((paramName == 'hex' || paramName == 'target') && $rootScope.hex) {
            $scope.action.params[i].value = $rootScope.hex;
        }
        else if(paramName == 'target' || paramName == 'mana_spend'){
            $scope.action.params[i].hide_input = true;
            $scope.action.params[i].hide_label = true;
        }
        if (!$scope.action.keepValues) {
            $scope.action.params[i].value = null;
            if(paramName == 'target'){
                $scope.action.params[i].options = null;
            }
        }
    }

    $scope.mapToggle = function(){
        // console.log('Emit map toggle');
        $rootScope.waitingForMap = true;
        $rootScope.hex = null;
        $rootScope.$emit('myth:mapToggle');
    };

    $scope.actionOptionsUpdate = function(actionName){
        if(actionName == 'CastSpell'){
            var params = $scope.action.params;
            var targetParam = null;
            var manaParam = null;
            var spellParam = null;
            for(var i = 0; i < params.length; i++){
                if(params[i].name == 'spell'){
                    spellParam = params[i];
                }
                if(params[i].name == 'target'){
                    targetParam = params[i];
                }
                if(params[i].name == 'mana_spend'){
                    manaParam = params[i];
                }
            }
            var paramValue = spellParam.value;
            // console.log('Spell casting ' + paramValue);
            targetParam.hide_label = false;
            targetParam.hide_input = false;
            targetParam.showHexButton = false;
            targetParam.options = null;
            targetParam.type = 'string';
            manaParam.hide_input = false;
            manaParam.hide_label = false;
            if(paramValue == 'Bless'){
                targetParam.showHexButton = false;
                targetParam.type = 'options';
                targetParam.options = $scope.action.bless;
            }
            else if(paramValue == 'Heal'){
                targetParam.showHexButton = false;
                targetParam.type = 'options';
                targetParam.options = $scope.action.heal;
            }
            else if(paramValue == 'Ritual'){
                targetParam.showHexButton = false;
                targetParam.type = 'options';
                targetParam.options = $scope.action.ritual;
            }
            else if(paramValue == 'Scry'){
                targetParam.showHexButton = true;
                targetParam.type = 'string';
                manaParam.hide_input = true;
                manaParam.hide_label = true;
            }
            else if(paramValue == 'Teleport'){
                targetParam.showHexButton = true;
                targetParam.type = 'string';
                manaParam.hide_input = true;
                manaParam.hide_label = true;
            }
            else {
                targetParam.hide_label = true;
                targetParam.hide_input = true;
                manaParam.hide_input = true;
                manaParam.hide_label = true;
            }
            $scope.action.params = params;
            // console.log($scope.action.params);
        }
    };

    $scope.submit = function(){
        if($scope.action != null){
            var params = {};
            if($scope.action.params){
                for(var i = 0; i < $scope.action.params.length; i++){
                    var paramName = $scope.action.params[i].name;
                    var paramValue = $scope.action.params[i].value;
                    params[paramName] = paramValue;
                    // console.log(paramName + ' = ' + paramValue);
                }
            }
            // console.log(params);
            actionService.post($scope.position, $scope.action, params, function(){
                $uibModalInstance.close($scope.action);
            }, function(error){
                if(error.data.errors){
                  for(var i = 0; i < error.data.errors.length; i++){
                      for(var type in error.data.errors[i]){
                          $scope.errors[type] = error.data.errors[i][type];
                      }
                }
              } else {
                  $scope.error = error.data.error;
              }
            });
        }
    };

    $scope.cancel = function () {
        $uibModalInstance.dismiss('cancel');
    };
}]);