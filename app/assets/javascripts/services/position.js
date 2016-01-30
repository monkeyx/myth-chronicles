'use strict';

angular.module('mythChronicles').factory('positionService', ['$http','$q', '$auth', '$state', 'alertService', 
    function ($http, $q, $auth, $state, alertService) {
    var service = {
        game: game,
        games: games,
        character: character,
        armies: armies,
        settlements: settlements,
        position: position,
        lastPosition: lastPosition,
        uncachePosition: uncachePosition,
        map: map,
        clear: clear,
        create: create
    },
    cacheGame = null,
    cacheCharacter = null,
    cacheArmies = null,
    cacheSettlements = null,
    cachePositions = {},
    lastPositionId = 0,
    lastPositionType = null,
    cacheMap = {};

    return service;

    function handleAPIError(error){
        if(error.status == 404){
            $state.transitionTo('user.setup');
        } 
        else if(error.status == 403){
            $auth.signOut();
        }
        else {
            alertService.error(error);
        }
    }

    function clear(){
        lastPositionId = 0;
        lastPositionType = null;
        cacheGame = null;
        cacheCharacter = null;
        cacheArmies = null;
        cacheSettlements = null;
        cachePositions = {};
        cacheMap = {};
    }

    function game(){
        var deferred = $q.defer();
        if(cacheGame != null){
            deferred.resolve(cacheGame);
        }
        else {
            $http.get('/api/game').then(function(response){
                console.log('*** GAME ***');
                console.log(response.data);
                cacheGame = response.data;
                deferred.resolve(cacheGame);
            }).
            catch(function(error){
                handleAPIError(error);
            });
        }
        return deferred.promise;
    }

    function games(){
        var deferred = $q.defer();
        $http.get('/api/games').then(function(response){
            console.log('*** GAMES ***');
            console.log(response.data);
            deferred.resolve(response.data);
        }).
        catch(function(error){
            handleAPIError(error);
        });
        return deferred.promise;
    }

    function character(){
        console.log("*** GET CHARACTER ***")
        var deferred = $q.defer();
        if(cacheCharacter != null){
            deferred.resolve(cacheCharacter);
        }
        else {
            $http.get('/api/character').then( function(response){
                console.log('*** CHARACTER ***');
                console.log(response.data);
                cacheCharacter = response.data;
                deferred.resolve(cacheCharacter);
                if(cacheCharacter){
                    map(cacheCharacter.location.x, cacheCharacter.location.y).then(function(map){}); // pre-cache map
                }
            }).
            catch(function(error){
                handleAPIError(error);
            });
        }
        return deferred.promise;
    }

    function armies(){
        var deferred = $q.defer();
        if(cacheArmies != null){
            deferred.resolve(cacheArmies);
        }
        else {
            $http.get('/api/?armies=y').then( function(response){
                console.log('*** ARMIES ***');
                console.log(response.data);
                cacheArmies = response.data;
                deferred.resolve(cacheArmies);
            }).
            catch(function(error){
                handleAPIError(error);
            });
        }
        return deferred.promise;
    }

    function settlements(){
        var deferred = $q.defer();
        if(cacheSettlements != null){
            deferred.resolve(cacheSettlements);
        }
        else {
            $http.get('/api/?settlements=y').then( function(response){
                console.log('*** SETTLEMENTS ***');
                console.log(response.data);
                cacheSettlements = response.data;
                deferred.resolve(cacheSettlements);
            }).
            catch(function(error){
                handleAPIError(error);
            });
        }
        return deferred.promise;
    }

    function lastPosition(){
        if(lastPositionId > 0){
            return position(lastPositionType, lastPositionId);
        } else {
            return character();
        }
    }

    function uncachePosition(posId){
        if(cachePositions.hasOwnProperty(posId)){
            cachePositions[posId] = null;
        }
    }

    function position(posType, posId){
        lastPositionType = posType;
        lastPositionId = posId;
        var deferred = $q.defer();
        if(cachePositions.hasOwnProperty(posId) && cachePositions[posId]){
            deferred.resolve(cachePositions[posId]);
        }
        else {
            $http.get('/api/' + posType + '/' + posId).then( function(response){
                console.log('*** ' + posType + ' (' + posId + ') ***');
                console.log(response.data);
                cachePositions[posId] = response.data;
                cachePositions[posId].actionMap = {};
                for(var i = 0; i < cachePositions[posId].actions.length; i++){
                    var action = cachePositions[posId].actions[i];
                    cachePositions[posId].actionMap[action.name] = action;
                }
                deferred.resolve(cachePositions[posId]);
                // console.log('ACTIONS MAP:');
                // console.log(cachePositions[posId].actionMap);
                if(cachePositions[posId]){
                    map(cachePositions[posId].location.x, cachePositions[posId].location.y).then(function(map){}); // pre-cache map
                }
            }).
            catch(function(error){
                handleAPIError(error);
            });
        }
        return deferred.promise;
    }

    function map(x, y){
        var deferred = $q.defer();
        var mapKey = '::' + y + ':' + x;
        console.log('GET MAP');
        console.log('x = ' + x + ' y = ' + y);
        if(cacheMap.hasOwnProperty(mapKey)){
            console.log('CACHED');
            deferred.resolve(cacheMap[mapKey]);
        }
        else {
            console.log('NOT CACHED');
            $http.get('/api/map/' + x + '/' + y).then( function(response){
                console.log('*** MAP ***');
                console.log(response.data);
                var map = response.data;
                var map_array = [];
                for(var y in map){
                    if(map.hasOwnProperty(y)){
                        var row = [];
                        for(var x in map[y]){
                            if(map[y].hasOwnProperty(x)){
                                row.push(map[y][x]);
                            }
                        }
                        map_array.unshift(row);
                    }
                }
                map.array = map_array;
                cacheMap[mapKey] = map;
                // console.log('*** CACHED MAP ' + mapKey + ' ARRAY ***')
                // console.log(map.array);
                deferred.resolve(map);
            }).
            catch(function(error){
                handleAPIError(error);
            });
        }
        return deferred.promise;
    }

    function create(game_id, character_type, name){
        var deferred = $q.defer();
        $http.post('/api/character', {
            game_id: game_id,
            character_type: character_type,
            name: name
        }).then( function(response){
            deferred.resolve(response.data);
        }).
        catch(function(error){
            deferred.reject(error.data);
        });
        return deferred.promise;
    }
}]);