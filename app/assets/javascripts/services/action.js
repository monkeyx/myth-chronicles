'use strict';

angular.module('mythChronicles').factory('actionService', ['$rootScope', '$http', '$resource', 'localStorageService', 'poller', 'alertService' , 
  function ($rootScope, $http, $resource, localStorageService, poller, alertService) {
    var service = {
        start: start,
        post: post,
        poll: poll,
        count: count,
        list: list,
        cancel: cancel
    },
    pollers = {};
    return service;

    function start(){
      var lsKeys = localStorageService.keys();
      for(var i = 0; i < lsKeys.length; i++){
        poll(localStorageService.get(lsKeys[i]), lsKeys[i]);
      }
    }

    function post(position, action, params, successCallback, errorCallback){
      $http.post('/api/' + position.type + '/' + position.id + '/' + action.name, params).then ( function(response){
          // alertService.add('info', 'Submitted action ' + $scope.action.display_name);
          // console.log(response.data);
          var actionName = position.name + ' (' + position.id + ') ' + action.display_name;
          var jobId = response.data.id;
          $rootScope.$emit('myth:action-post');
          $rootScope.$emit('myth:action');
          poll(actionName, jobId);
          if(successCallback)
            successCallback();
      }, function(error){
          console.log(error);
          if(errorCallback)
            errorCallback(error);
          
      });
    }

    function poll(actionName, jobId) {
        console.log("Polling " + actionName + " [" + jobId + "]");
        localStorageService.set(jobId, actionName);
        var myResource = $resource('/api/status/' + jobId);
        var myPoller = poller.get(myResource, {delay: 15000});
        pollers[jobId] = myPoller;
        $rootScope.showLoadingIndicator = true;
        $rootScope.$emit('myth:action-poll');
        $rootScope.$emit('myth:action');
        myPoller.promise.then(null, null, function(response){
            // console.log(response.status);
            if(response.status.completed){
                console.log('Job done');
                myPoller.stop();
                myPoller.remove();
                localStorageService.remove(jobId);
                alertService.add('info', actionName + ': ' + response.status.message);
                $rootScope.$emit('myth:action-success');
                $rootScope.$emit('myth:action');
            }
            if(response.status.failed){
                console.log('Job failed');
                myPoller.stop();
                myPoller.remove();
                localStorageService.remove(jobId);
                alertService.add('warning', actionName + ': ' + response.status.message);
                $rootScope.$emit('myth:action-failure');
                $rootScope.$emit('myth:action');
            }
            if(count() < 1){
              $rootScope.showLoadingIndicator = false;
            }
        });
    }

    function count() {
      return localStorageService.keys().length;
    }

    function list() {
      var actions = [];
      for(var i = 0; i < count(); i++){
          actions.push({
            id: localStorageService.keys()[i], 
            name: localStorageService.get(localStorageService.keys()[i])
          });
      }
      console.log('Pending Jobs');
      console.log(actions);
      return actions;
    }

    function cancel(jobId) {
      if(jobId){
        if(pollers.hasOwnProperty(jobId)){
          pollers[jobId].stop();
          pollers[jobId].remove();
        }
        $http.delete('/api/status/' + jobId).then( function(){
          localStorageService.remove(jobId);
          if(count() < 1){
            $rootScope.showLoadingIndicator = false;
          }
          $rootScope.$emit('myth:action-cancel');
          $rootScope.$emit('myth:action');
        }, function(){
          localStorageService.remove(jobId);
          if(count() < 1){
            $rootScope.showLoadingIndicator = false;
          }
          $rootScope.$emit('myth:action-cancel');
          $rootScope.$emit('myth:action');
        });
      }
    }

}]);