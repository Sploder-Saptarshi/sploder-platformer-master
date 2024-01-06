/**
* Fuz2d: 2d Gaming Engine
* ----------------------------------------------------------------
* ----------------------------------------------------------------
* Copyright (C) 2008 Geoffrey P. Gaudreault
* 
*/


package fuz2d.action.physics {

	import flash.geom.Point;
	import flash.utils.Dictionary;
	import fuz2d.util.Geom2d;
	
	import fuz2d.action.physics.SimulationObject;
	
	public class SimulationGrid {
		
		private var _scaleX:uint;
		private var _scaleY:uint;

		private var _minScale:uint;
		private var _maxScale:uint;
		
		public function get minScale():uint { return _minScale; }
		public function get maxScale():uint { return _maxScale; }
		
		private var _grid:Dictionary;
		private var _areaMap:Dictionary;
		
		//
		//
		public function SimulationGrid(scaleX:uint = 10, scaleY:uint = 10) {
			
			_scaleX = scaleX;
			_scaleY = scaleY;
			
			_minScale = Math.min(_scaleX, _scaleY);
			_maxScale = Math.max(_scaleX, _scaleY);
		
			init();
			
		}
		
		//
		//
		private function init ():void {
			
			_grid = new Dictionary();
			_areaMap = new Dictionary(true);
			
		}
		
		//
		//
		public function register (obj:SimulationObject):void {
					
			if (obj != null) {
				
				var x:int;
				var y:int;
				
				if (obj.objectRef.width <= minScale && obj.objectRef.height <= minScale) {
					
					x = Math.floor(obj.position.x / _scaleX);
					y = Math.floor(obj.position.y / _scaleY);
	
					if (_areaMap[obj] == null) {
						
						if (cellAt(x, y).indexOf(obj) == -1) cellAt(x, y).push(obj);
						_areaMap[obj] = { x: x, y: y };
						
					}
				
				} else {
						
					var cells:Array = getCellsFor(obj);
					
					_areaMap[obj] = [];
					
					for each (var c:Object in cells) {
						
						if (cellAt(c.x, c.y).indexOf(obj) == -1) cellAt(c.x, c.y).push(obj);
						_areaMap[obj].push( { x: c.x, y: c.y } );	

					}
	
				}
				
			}
			
		}
		
		//
		//
		public function unregister (obj:SimulationObject):void {
					
			if (_areaMap[obj] != null) {
				
				update(obj, true);
				_areaMap[obj] = null;
				delete _areaMap[obj];

			}
			
		}
		
		//
		//
		protected function getCellsFor (obj:SimulationObject):Array {
			
			var a:Array = [];
			var w:Number = obj.objectRef.width * 0.5;
			var h:Number = obj.objectRef.height * 0.5;
			
			var minX:int = Math.floor((obj.position.x - w) / _scaleX);
			var maxX:int = Math.floor((obj.position.x + w) / _scaleX);
			var minY:int = Math.floor((obj.position.y - h) / _scaleY);
			var maxY:int = Math.floor((obj.position.y + h) / _scaleY);
			
			_areaMap[obj] = [];
			
			for (var j:int = minY; j <= maxY; j++) {
				
				for (var i:int = minX; i <= maxX; i++) {
					
					a.push({ x: i, y: j });
					
				}							
				
			}
			
			return a;
			
		}
		
		//
		//
		public function update (obj:SimulationObject, remove:Boolean = false):void {
			
			var changed:Boolean = false;
			
			if (obj != null) {
				
				var x:int = Math.floor(obj.position.x / _scaleX);
				var y:int = Math.floor(obj.position.y / _scaleY);
	
				var o:Object = _areaMap[obj];
				var c:Array = cellAt(x, y);
				
				if (o != null) {
					
					var oldcell:Array;
					var idx:uint;
					
					if (o is Array) {
					

						for each (var cd:Object in o) {
							oldcell = cellAt(cd.x, cd.y);
							idx = oldcell.indexOf(obj);
							if (idx != -1) oldcell.splice(idx, 1);
						}
						
						_areaMap[obj] = null;
						delete _areaMap[obj];
						
						if (!remove) register(obj);
						
					} else {
						
						if (x != o.x || y != o.y || remove) {
							
							oldcell = cellAt(o.x, o.y);
							idx = oldcell.indexOf(obj);
							
							if (idx != -1) {
								oldcell.splice(idx, 1);
								_areaMap[obj] = null;
								delete _areaMap[obj];
							}
							
							changed = true;
							
						} else {
							
							return;
							
						}
						
					}
					
				}
				
				if (changed && !remove) {
					
					if (c.indexOf(obj) == -1) c.push(obj);
					_areaMap[obj] = { x: x, y: y };
			
				}
			
			}
			
		}
		
		//
		//
		private function cellAt (x:int, y:int):Array {
			
			var id:String = "c" + x + "_" + y;
			
			if (_grid[id] == null) {
				_grid[id] = [];
			}
			
			return _grid[id];
			
		}
		
		//
		//
		public function getNeighborsOf (obj:Object, distSort:Boolean = true, horizontalDistOnly:Boolean = false, neighbors:Array = null):Array {
			
			if (neighbors == null) neighbors = [];
			else while (neighbors.length > 0) neighbors.pop();
			
			if (obj != null) {
				
				var x:int = Math.floor(obj.position.x / _scaleX);
				var y:int = Math.floor(obj.position.y / _scaleY);
				
				var w:int = 1;
				var h:int = 1;
				
				if (obj is SimulationObject) {
					if (SimulationObject(obj).objectRef.width > _scaleX * 2) w = 2;
					if (SimulationObject(obj).objectRef.height > _scaleY * 2) h = 2;
				}
				
				for (var j:int = y + h; j >= y - h; j--) {
						
					for (var i:int = x + w; i >= x - w; i--) {
							
						neighbors = neighbors.concat(cellAt(i, j));
						
					}					
					
				}				

			}
			
			while (neighbors.indexOf(obj) != -1) neighbors.splice(neighbors.indexOf(obj), 1);

			if (distSort) {
				
				var nD:Array = [];
				var neighbor:SimulationObject;
				
				if (!horizontalDistOnly) {
					for each (neighbor in neighbors) {
						nD.push( { dist: Geom2d.squaredDistanceBetweenPoints(obj.position, neighbor.position), obj: neighbor } );
					}
				} else {
					for each (neighbor in neighbors) {
						nD.push( { dist: Geom2d.horizontalDistanceBetweenPoints(obj.position, neighbor.position), obj: neighbor } );
					}	
				}
				
				nD.sortOn("dist", Array.NUMERIC | Array.DESCENDING);
				neighbors = [];
				for each (var dd:Object in nD) neighbors.push(dd.obj);
				
			}

			return neighbors;
			
		}
		
		
		//
		//
		public function getNeighborsNear (pt:Point, distSort:Boolean = true, horizontalDistOnly:Boolean = false, range:int = 1):Array {
			
			var neighbors:Array = [];
			
			var x:int = Math.floor(pt.x / _scaleX);
			var y:int = Math.floor(pt.y / _scaleY);		
			
			for (var j:int = y + range; j >= y - range; j--) {
					
				for (var i:int = x + range; i >= x - range; i--) {
						
					neighbors = neighbors.concat(cellAt(i, j));
					
				}					
				
			}				
			
			if (distSort) {
				
				var nD:Array = [];
				var neighbor:SimulationObject;
				
				if (!horizontalDistOnly) {
					for each (neighbor in neighbors) {
						nD.push( { dist: Geom2d.squaredDistanceBetweenPoints(pt, neighbor.position), obj: neighbor } );
					}
				} else {
					for each (neighbor in neighbors) {
						nD.push( { dist: Geom2d.horizontalDistanceBetweenPoints(pt, neighbor.position), obj: neighbor } );
					}	
				}
				
				nD.sortOn("dist", Array.NUMERIC);
				neighbors = [];
				for each (var dd:Object in nD) neighbors.push(dd.obj);
				
			}

			return neighbors;
			
		}
		
		//
		//
		public function getNeighborsAlong (ptA:Point, ptB:Point, distSort:Boolean = true):Array {
			
			var neighbors:Array = [];
			
			var xA:int = Math.floor(((ptA.x <= ptB.x) ? ptA.x : ptB.x) / _scaleX);
			var yA:int = Math.floor(((ptA.y <= ptB.y) ? ptA.y : ptB.y) / _scaleY);
			var xB:int = Math.floor(((ptA.x > ptB.x) ? ptA.x : ptB.x) / _scaleX);
			var yB:int = Math.floor(((ptA.y > ptB.y) ? ptA.y : ptB.y) / _scaleY);	
			
			for (var j:int = yB + 1; j >= yA - 1; j--) {
					
				for (var i:int = xB + 1; i >= xA - 1; i--) {
						
					neighbors = neighbors.concat(cellAt(i, j));
					
				}					
				
			}				
			
			if (distSort) {
				
				var nD:Array = [];
				
				for each (var neighbor:SimulationObject in neighbors) nD.push( { dist: Geom2d.squaredDistanceBetweenPoints(ptA, neighbor.position), obj: neighbor } );
				nD.sortOn("dist", Array.NUMERIC);
				neighbors = [];
				for each (var dd:Object in nD) neighbors.push(dd.obj);
				
			}

			return neighbors;
			
		}
		
		public function end ():void {
			
			_grid = null;
			_areaMap = null;
			
		}
		
	}
	
}
