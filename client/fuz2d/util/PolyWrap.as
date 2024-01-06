﻿package fuz2d.util {
	
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import fuz2d.util.Geom2d;

	/**
	* ...
	* @author Geoff Gaudreault
	*/
	public class PolyWrap {
		
		protected var _container:Sprite;
		
		public var rotation:Number;
		
		protected var _hullOffset:Number = 0;
		protected var _angleSeparation:Number = 5;
		protected var _precision:Number = 10;
		protected var _angleTolerance:Number = 0.7;
		
		public var points:Array;
		public var angles:Array;
		
		protected var _startWidth:Number;
		protected var _startHeight:Number;
		
		protected var _clipY:Number = 0;
		
		protected var _boundsSprite:Sprite;
		
		//
		//
		function PolyWrap (boundsSprite:Sprite, angleSeparation:int = 5, precision:int = 10, angleTolerance:Number = 0.7, hullOffset:Number = 0, clipY:Number = 0) {
		
			init(boundsSprite, angleSeparation, precision, angleTolerance, hullOffset, clipY);
			
		}
		
		//
		//
		protected function init (boundsSprite:Sprite, angleSeparation:int = 5, precision:int = 10, angleTolerance:Number = 0.7, hullOffset:Number = 0, clipY:Number = 0):void {
			
			_boundsSprite = boundsSprite;
			_angleSeparation = Math.max(1, angleSeparation);
			_precision = Math.max(1, precision);
			_angleTolerance = Math.max(0.3, angleTolerance);
			_hullOffset = hullOffset;
			_clipY = clipY;
			
			_startWidth = _boundsSprite.width;
			_startHeight = _boundsSprite.height;
				
		}
		
		//
		//
		public function getBoundingPoints ():Array {
			
			var pa:Number;
			var pp:Point;
			var op:Point;
			var np:Point;
			var fp:Point;
			
			var i:int;
			
			points = new Array(361);
			angles = [];
			
			var errorDist:Number = 20 + Math.max(20, (Math.max(_startWidth + 10, _startHeight + 10) * Math.PI) / (360 / _angleSeparation) + (_hullOffset / Math.PI));
			
			var sweep:Function = function (mc:Sprite, startAngle:Number, endAngle:Number, angleSeparation:Number, precision:Number, offset:Number, maxCheck:Number, points:Array, angles:Array, recursionDepth:int = 1):void {
				
				var cp:Point;
				var mp:Point;
				
				var minDist:Number;
				var maxDist:Number;
				var testDist:Number
				var diffDist:Number;
				
				var myPoint:Point;
				
				for (var angle:int = startAngle; angle < endAngle; angle += angleSeparation) {
					
					minDist = 0;
					maxDist = maxCheck;

					if (points[angle] == undefined) {
					
						do {
							
							testDist = minDist + ((maxDist - minDist) * 0.5);
							
							myPoint = Point.polar(testDist, angle * Geom2d.dtr);

							myPoint = mc.localToGlobal(myPoint);

							if (mc.hitTestPoint(myPoint.x, myPoint.y, true)) {
								
								minDist = testDist;


							} else {
								
								maxDist = testDist;

							}
							
							diffDist = maxDist - minDist;
							
						} while (diffDist > precision);
			
						cp = Point.polar(minDist + offset, angle * Geom2d.dtr);

					} else {
						
						cp = points[angle];
						
					}
					
					if (mp != null) {

						if (Point.distance(mp, cp) >= errorDist) {
							
							if (Math.floor(angleSeparation * 0.33) > 1 && recursionDepth < 3) {
								
								arguments.callee(mc, angle - angleSeparation, angle - Math.floor(angleSeparation * 0.33), Math.floor(angleSeparation * 0.33), precision, offset, maxCheck, points, angles, recursionDepth + 1);
								
							} 

						}
						
					}
					
					if (points[angle] == null) {

						points[angle] = cp;
						angles.push(angle);

					}
					
					mp = cp;
					
				}			
				
			}
			
			sweep(_boundsSprite, 0, 360, _angleSeparation, _precision, _hullOffset, Math.max(_startWidth + 10, _startHeight + 10), points, angles);

			var accum:Number = 0;
			var distaccum:Number = 0;
			// optimize
			

			for (i = angles.length - 2; i > 0; i--) {

				op = points[angles[i + 1]];
				np = points[angles[i]];
				pp = points[angles[i - 1]];	
	
				var a1:Number = Geom2d.angleBetweenPoints(pp, np);
				var a2:Number = Geom2d.angleBetweenPoints(np, op);
				
				if (accum + Math.abs(a1) - Math.abs(a2) < _angleTolerance) {
					
					points[angles[i]] = null;
					angles.splice(i, 1);
					
					accum += Math.abs(Math.abs(a1) - Math.abs(a2));

				} else {
					
					accum = 0;
					
					var dd:Number = Geom2d.squaredDistanceBetweenPoints(pp, np);
				
					if (distaccum + dd < (_precision * _precision) * 1.5) {
						
						points[angles[i]] = null;
						angles.splice(i, 1);
						
						distaccum += dd;
						
					} else {
						
						distaccum = 0;
						
					}
					
				}
				
			}
			
			points[angles[angles.length - 1]] = null;
			angles.splice(angles.length - 1, 1);
				
			if (_clipY != 0) {
				
				for (i = 0; i < angles.length; i++) {		
					np = points[angles[i]];
					if (_clipY > 0) np.y = Math.min(_clipY, np.y);
					else np.y = Math.max(_clipY, np.y);
				}
				
			}
				

			// draw
			fp = points[0];
			
			var newPoints:Array = [];
		
			for (i = 0; i < angles.length; i++) {
					
				newPoints.push(points[angles[i]]);
				
			}
			
			return newPoints;

		}
		
	}
	
}