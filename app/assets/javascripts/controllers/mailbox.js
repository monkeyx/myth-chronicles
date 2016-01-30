'use strict';

mythChronicles.controller('MailboxCtrl',['$http', '$auth', '$scope', '$rootScope', '$state', '$stateParams', 'positionService', 
	function ($http, $auth, $scope, $rootScope, $state,  $stateParams, positionService) {
    
    $scope.messageForm = {};
    $scope.loadingMailbox = true;
    $scope.composeFormVisible = false;
    $scope.sendingMessage = false;
    $scope.recipients = [];

    $rootScope.mailbox = $stateParams.mailbox;
    if(!$rootScope.mailbox){
        $rootScope.mailbox = 'inbox';
    }
    console.log('MAILBOX = ' + $rootScope.mailbox);
    
    $scope.conversation_id = null;
    $scope.conversation = null;

    $http.get('/api/recipients').
        then(function(response){
            // console.log(response.data);
            $scope.recipients = response.data;
        }).
        catch(function(response){
            // console.log(response.data);
            $scope.error = response.data.error;
            $scope.conversation_id = null;
        });

    $scope.$watch('conversation_id', function(){
        GetConversation();
    });

    $scope.hideAlert = function(){
        $scope.notice = null;
        $scope.error = null;
    }

    $scope.toggleComposeForm = function(){
        $scope.notice = null;
        $scope.error = null;
        $scope.conversation = null;
        $scope.conversation_id = null;
    	$scope.composeFormVisible = !$scope.composeFormVisible;
        $scope.reloadPage = true;
    };

    $scope.showConversation = function(id){
        $scope.conversation_id = id;
    };

    $scope.trashConversation = function(){
        if($scope.conversation_id){
            $http.delete('/api/messages/' + $scope.conversation_id).
            then(function(response){
                $scope.reloadPage = true;
                $scope.conversation = null;
                $scope.conversation_id = null;
                $scope.composeFormVisible = false;
            }).
            catch(function(error){
                console.log(error);
                $scope.error = error.data.error;
            });
        }
    }

    $scope.submitMessage = function(messageForm){
        console.log(messageForm);
        $scope.sendingMessage = true;
        $scope.composeFormVisible = false;
        if($scope.conversation_id){
            messageForm.conversation_id = $scope.conversation_id;
        }
        $http.post('/api/messages', messageForm).
        then(function(response){
            $scope.sendingMessage = false;
            if(!$scope.conversation){
                $scope.notice = 'Message sent';
            }
            GetConversation();
            $scope.messageForm = {};
        }).
        catch(function(error){
            console.log(error);
            $scope.sendingMessage = false;
            $scope.error = error.data.error;
        });
    };
    
    $scope.$on('pagination:loadPage', function (event, status, config) {
    	console.log('Pagination loaded');
    	$scope.loadingMailbox = false;
    });

    function GetConversation(){
        if($scope.conversation_id && $scope.conversation_id > 0){
            $http.get('/api/messages/' + $scope.conversation_id).
                then(function(response){
                    console.log('*** CONVERSATION ***');
                    console.log(response.data);
                    $scope.conversation = response.data;
                    $scope.composeFormVisible = true;
                    $scope.loadingMailbox = false;
                }).
                catch(function(error){
                    console.log(error);
                    $scope.error = error.data.error;
                });
        }
        
    }
}]);