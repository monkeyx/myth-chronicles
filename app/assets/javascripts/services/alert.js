'use strict';

angular.module('mythChronicles').factory('alertService', ['$rootScope',
    function ($rootScope) {
    var service = {
        add: add,
        error: error,
        clear: clear,
        get: get
    },
    alerts = [];

    return service;

    function add(type, msg) {
        $rootScope.$emit('myth:alert-add');
        return alerts.unshift({
            type: type,
            msg: msg,
            close: function() {
                return closeAlert(this);
            }
        });
    }

    function error(error){
        if(error && error.data && error.data.error){
            add('error', error.data.error);
        }
    }

    function clear(){
        alerts = [];
    }

    function get() {
        return alerts;
    }
}]);