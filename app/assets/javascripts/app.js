'use strict';

var mythChronicles = angular.module('mythChronicles',[
    'ngAnimate',
    'ipCookie',
    'ngResource',
    'ui.router',
    'ngSanitize',
    'ngTouch',
    'ng-token-auth',
    'emguo.poller', 
    'LocalStorageModule',
    'bgf.paginateAnything',
    'pageslide-directive',
    'matchMedia',
    'ui.bootstrap'
]);

String.prototype.capitalizeFirstLetter = function() {
    return this.charAt(0).toUpperCase() + this.slice(1);
}

mythChronicles.config(['$authProvider', function($authProvider) {
    $authProvider.configure({
        apiUrl: '/api',
        storage: 'localStorage'
    });
}]);

mythChronicles.config(['localStorageServiceProvider', function (localStorageServiceProvider) {
  localStorageServiceProvider
    .setPrefix('mcActions')
    .setNotify(true, true);
}]);

mythChronicles.directive('ccPreloadImage', [function() {
    return {
        restrict: "E",
        scope: {
            filenames: '=ccFilenames',
        },
        link: function(scope, element, attrs) {
            
             scope.$watch('filenames', function(filenamesObj) {
 
                if(typeof filenamesObj === 'undefined')
                    return;
 
                var imageArray = [];
                for (var i = 0; i < filenamesObj.length; i++) {            
                    imageArray[i] = new Image();
                    imageArray[i].src = attrs.ccPath + '/' + filenamesObj[i].toLowerCase()+'.png';
                }
 
            });
            
        }
    };
}]);
