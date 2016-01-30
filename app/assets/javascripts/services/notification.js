'use strict';

angular.module('mythChronicles').factory('notificationService', ['$rootScope', '$http', '$interval', 'alertService', 'positionService',
    function ($rootScope, $http, $interval, alertService, positionService) {
    var service = {
        start: start,
        cancel: cancel,
        clear: clear
    },
    positions = {};

    return service;

    function start(posType, posId) {
        if(!positions.hasOwnProperty(posId)){
            positions[posId] = {id: posId, type: posType, since: Date.now()};
            positions[posId].checkNotifications = function(){
                if(positions.hasOwnProperty(posId) && positions[posId]){
                    // console.log('Checking for notifications for position ' + posId);
                    $http.get('/api/' + positions[posId].type + '/' + posId + '/notifications?since=' + positions[posId].since).
                        then(function(response){
                            for(var i = 0; i < response.data.length; i++){
                                alertService.add('info', response.data[i].summary);
                            }
                            if(response.data.length > 0){
                                positionService.uncachePosition(posId);
                                positionService.position(positions[posId].type, posId);
                            }
                            // console.log('Notifications for position ' + posId);
                            // console.log(response.data);
                            positions[posId].since = Date.now();
                            $rootScope.$emit('myth:notification');
                    });
                }
            };
            positions[posId].interval = $interval(positions[posId].checkNotifications, 15000);
        }
    }

    function cancel(posId){
        if(positions.hasOwnProperty(posId) && positions[posId]){
            $interval.cancel(positions[posId].interval);
            positions[posId] = null;
        }
    }

    function clear(){
        for(var posId in positions){
            cancel(posId);
        }
        positions = {};
    }
}]);