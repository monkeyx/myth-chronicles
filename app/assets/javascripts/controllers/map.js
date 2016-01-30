'use strict';

mythChronicles.controller('MapCtrl', ['$scope', '$rootScope', 'positionService',
    function($scope, $rootScope, positionService){
    $scope.checked = false;

    $scope.element        = document.getElementById("stage");
    $scope.element.height = window.innerHeight;
    $scope.element.width  = window.innerWidth;

    $scope.stage   = new createjs.Stage("stage");
    $scope.stage.x = window.innerWidth/2;
    $scope.stage.y = window.innerHeight/2;

    $scope.grid             = new Grid();
    $scope.grid.tileSize    = 50;
    $scope.grid.tileSpacing = 0;
    $scope.grid.pointyTiles = false;

    $scope.stageTransformer = new StageTransformer().initialize({
        element: $scope.element,
        stage: $scope.stage
    });

    $scope.stageTransformer.addEventListeners();
    $scope.stage.enableMouseOver(20);

    var tick = function (event) {
        if($scope.checked)
            $scope.stage.update();
    };

    tick();

    createjs.Ticker.setFPS(30);
    createjs.Ticker.addEventListener("tick", tick);

    function DrawMap(){
        $scope.stage.removeAllChildren();
        $scope.stage.update();

        var towerImage = new Image();
        towerImage.src = "/icons/tower.png";
        towerImage.onload = HandleTowerImageLoad;

        var cityImage = new Image();
        cityImage.src = "/icons/city.png";
        cityImage.onload = HandleCityImageLoad;

        var lairImage = new Image();
        lairImage.src = "/icons/lair.png";
        lairImage.onload = HandleLairImageLoad;

        var armyImage = new Image();
        armyImage.src = "/icons/army.png";
        armyImage.onload = HandleArmyImageLoad;

        var dungeonImage = new Image();
        dungeonImage.src = "/icons/dungeon.png";
        dungeonImage.onload = HandleDungeonImageLoad;

        $scope.mapCenter = $scope.grid.getCenterXY($scope.mapX, $scope.mapY);

        $scope.coordinates = [];

        var coordinates = $scope.grid.hexagon($scope.mapX, $scope.mapY, 5, true);

        for(var i = 0; i < coordinates.length; i++){
            var q = coordinates[i].q,
                r = coordinates[i].r;

            if($scope.map.hasOwnProperty(r) && $scope.map[r].hasOwnProperty(q)){
                $scope.coordinates.push(coordinates[i]);
            }
        }

        for (var i = 0; i < $scope.coordinates.length; i++) {
            var q = $scope.coordinates[i].q,
                r = $scope.coordinates[i].r,
                center = $scope.grid.getCenterXY(q, r),
                hexagon = new createjs.Shape(),
                text = new createjs.Text();

            center.x -= $scope.mapCenter.x;
            center.y -= $scope.mapCenter.y;

            var terrain = $scope.map[r][q].terrain,
                terrainColour = GetTerrainColour(terrain);

            var territory = $scope.map[r][q].territory;

            var territoryColour = '#000';
            if(territory && territory.colour){
                territoryColour = territory.colour;
            }

            hexagon.graphics
              .beginFill(terrainColour)
              .beginStroke(territoryColour)
              .drawPolyStar(0, 0, $scope.grid.tileSize, 6, 0, 0);

            text.set({text: '(' + q + ', ' + r + ')', textAlign: 'center'});
            text.x = center.x;
            text.y = center.y + ($scope.grid.tileSize / 2);

            $scope.coordinates[i].container = new createjs.Container();
            $scope.coordinates[i].container.addChild(hexagon, text);

            hexagon.q = q;
            hexagon.r = r;
            hexagon.x = center.x;
            hexagon.y = center.y;

            hexagon.addEventListener("click", function (event) {
                if (!$scope.stageTransformer.mouse.moved) {
                    var q = event.target.q, r = event.target.r;
                    $scope.select(q,r);
                }
            });

            hexagon.addEventListener("mouseover", function (event) {
                var q = event.target.q, r = event.target.r;
                $scope.hover(q,r);
            });    

            $scope.stage.addChild($scope.coordinates[i].container);
        }
    }

    function HandleImageLoad(image, propertyName, offset){
        // console.log('Handling ' + propertyName);
        for (var i = 0; i < $scope.coordinates.length; i++) {
            var q = $scope.coordinates[i].q,
              r = $scope.coordinates[i].r;
            
            if($scope.map && $scope.map.hasOwnProperty(r) && $scope.map[r].hasOwnProperty(q)){
                var hex = $scope.map[r][q];
                // console.log('(' + q + ', ' + r + '): ' + hex[propertyName]);
                if(hex[propertyName] && (!(hex[propertyName] instanceof Array) || hex[propertyName].length > 0)){
                    console.log('(' + q + ', ' + r + '): ' + hex[propertyName]);
                    var center = $scope.grid.getCenterXY(q, r);
                    center.x -= $scope.mapCenter.x;
                    center.y -= $scope.mapCenter.y;
                    var bitmap = new createjs.Bitmap(image);
                    bitmap.x = center.x - (image.width / 2);
                    bitmap.y = center.y - (image.height / 2);

                    if(offset){
                        bitmap.x += offset;
                    }

                    $scope.coordinates[i].container.addChild(bitmap);
                }
            }
        }
    }

    function HandleTowerImageLoad(event){
        var image = event.target;
        HandleImageLoad(image, 'tower');
    }

    function HandleCityImageLoad(event){
        var image = event.target;
        HandleImageLoad(image, 'city');
    }

    function HandleLairImageLoad(event){
        var image = event.target;
        HandleImageLoad(image, 'lair');
    }

    function HandleArmyImageLoad(event){
        var image = event.target;
        HandleImageLoad(image, 'armies', 22);
    }

    function HandleDungeonImageLoad(event){
        var image = event.target;
        HandleImageLoad(image, 'dungeon', -22);
    }

    function GetTerrainColour(terrain){
        switch(terrain){
            case 'barren':
                return '#e3dac9';
            case 'desert':
                return '#ffef00';
            case 'forest':
                return '#228b22';
            case 'hill':
                return '#8db600';
            case 'mountain':
                return '#848482';
            case 'plains':
                return '#fae7b5';
            case 'river':
                return '#1ec8ff';
            case 'scrubland':
                return '#bdb76b';
            case 'sea':
                return '#1ea3ff';
            case 'swamp':
                return '#556b2f';
            case 'volcano':
                return '#e32636';
            case 'wasteland':
                return '#ffffff';
            default:
                return '#eef';
        }
    }

    $scope.show = function(){
        $rootScope.$emit('myth:mapShown');
        positionService.lastPosition().then(function(position){
            // console.log('GOT LAST POSITION');
            // console.log(position);
            positionService.map(position.location.x, position.location.y).then(function(map){
                $scope.mapX = position.location.x;
                $scope.mapY = position.location.y;
                $scope.map = map;
                // console.log($scope.map);
                DrawMap();
                $scope.checked = true;
            });
        });
    }

    $scope.hide = function(){
        $rootScope.$emit('myth:mapHidden');
        $scope.hoverLabel = '';
        $scope.checked = false;
    }

    $scope.toggle = function(){
        if(!$scope.checked){
            $scope.show();
        } else {
            $scope.hide();
        }
    }
    $scope.select = function(x,y){
        // console.log('SELECT: ' + x + ',' + y);
        $rootScope.hex = $scope.map[y][x].id;
        $scope.hide();
        $scope.$apply();
    };
    $scope.hover = function(x,y){
        // console.log('HOVER: ' + x + ', ' + y);
        if($scope.map && $scope.map.hasOwnProperty(y) && $scope.map[y].hasOwnProperty(x)){
            var hex = $scope.map[y][x];
            $scope.hoverLabel = '#' + hex.id + ': ' + hex.terrain.capitalizeFirstLetter();
            if(hex.city){
                $scope.hoverLabel = $scope.hoverLabel + ': ' + hex.city.name; 
            }
            else if(hex.tower){
                $scope.hoverLabel = $scope.hoverLabel + ': ' + hex.tower.name;
            }
            else if(hex.lair){
                $scope.hoverLabel = $scope.hoverLabel + ': ' + hex.lair.name;
            } 
            else if(hex.territory.name){
                $scope.hoverLabel = $scope.hoverLabel + ': Territory of ' + hex.territory.name;
            }
            if(hex.armies.length == 1){
                $scope.hoverLabel = $scope.hoverLabel + ': ' + hex.armies[0].name;
            }
            else if(hex.armies.length > 0){
                $scope.hoverLabel = $scope.hoverLabel + ': ' + hex.armies.length + ' armies';
            }
            if(hex.dungeon){
                $scope.hoverLabel = $scope.hoverLabel + ': ' + hex.dungeon.name;
            }
        }
        $scope.$apply();
        // console.log($scope.hoverLabel);
    };

    $scope.showWorldMap = function(){
        positionService.game().then(function(game){
            $scope.game = game;
            var world_map_src = "/map/" + game.id;
            window.open(world_map_src); 
        });
    };

    $rootScope.$on('myth:mapToggle', function(event, args) {
        // console.log('Received map toggle');
        $scope.toggle();
    });
}]);