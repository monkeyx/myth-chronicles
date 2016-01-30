'use strict';

mythChronicles.controller('SetupCtrl',['$auth', '$scope', '$rootScope', '$state', '$interval', '$http', 'positionService', 
	function ($auth, $scope, $rootScope, $state, $interval, $http, positionService) {
    
    if(!$rootScope.currentUser){
        $state.transitionTo('login');
        return;
    }

    if($rootScope.currentUser.character){
        $state.transitionTo('user.dashboard');
        return;
    }

    $scope.setupInProgress = $rootScope.currentUser.character_type;
    $scope.loadingGames = true;
    $scope.error = null;

    $scope.setup = {
        game: null,
        character_type: null,
        name: null,
        ready: function(){
            return this.game && this.character_type && this.name && this.name.length > 2;
        },
        showGame: function(){
            return !this.game;
        },
        showCharacterType: function(){
            return this.game && !this.character_type;
        },
        showName: function(){
            return this.game && this.character_type;
        }

    };

    $scope.selectCharacterType = function(character_type){
        $scope.setup.character_type = character_type;
    };

    $scope.gameSelected = function(game){
        $scope.game = game;
    };

    $scope.back = function(){
        if($scope.setup.name){
            $scope.setup.name = null;
            return;
        }
        if($scope.setup.character_type){
            $scope.setup.character_type = null;
            return;
        }
        if($scope.setup.game){
            $scope.setup.game = null;
            return;
        }
    }

    $scope.submit = function(){
        $scope.error = null;
        $scope.setupInProgress = true;
        positionService.create($scope.setup.game, $scope.setup.character_type, $scope.setup.name).then(function(response){
            console.log(response);
            var checkSetupComplete = function(){
                $http.get('/api/user').then( function(response){
                    $rootScope.currentUser = response.data;
                    if($rootScope.currentUser.character){
                        $scope.setupInProgress = false;
                        $state.transitionTo('user.dashboard');
                        $interval.cancel($rootScope.checkSetupProgress);
                    }
                });
            };
            $rootScope.checkSetupProgress = $interval(checkSetupComplete, 3000);
        }).
        catch(function(error){
            $scope.setupInProgress = false;
            if(error && error != ""){
                console.log(error);
                $scope.error = error.error;
            } else {
                $scope.error = "Could not create character";
            }
        });
    }


    positionService.games().then(function(games){
        $scope.loadingGames = false;
        $scope.games = games;
    });

}]);