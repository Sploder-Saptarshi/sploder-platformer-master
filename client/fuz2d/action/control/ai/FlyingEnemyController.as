﻿package fuz2d.action.control.ai {
	
	import flash.events.Event;
	import flash.geom.Point;
	
	import fuz2d.action.control.PlayObjectController;
	import fuz2d.action.physics.*;
	import fuz2d.action.play.*;
	import fuz2d.library.ObjectFactory;
	import fuz2d.TimeStep;
	import fuz2d.util.Geom2d;
	
	
	/**
	* ...
	* @author Geoff Gaudreault
	*/
	public class FlyingEnemyController extends PlayObjectController {
		
		protected var _body:PlayObjectMovable;
		protected var _player:PlayObject;
		protected var _playerNear:Boolean = false;

		// int between 1 and 10;
		protected var _speed:int = 5;
		// int between 1 and 100;
		protected var _aggression:int = 50;
		protected var _weaponsRange:int = 0;
		protected var _projectile:String = "";
		protected var _fireDelay:int = 0;
		protected var _firePower:int = 100;
		
		private var _lastAttack:int = 0;
		private var _lastApproach:int = 0;
		private var _lastSound:int;
		
		private var _homePoint:Point;

		//
		//
		public function FlyingEnemyController (object:PlayObjectControllable, speed:int = 5, aggression:int = 50, weaponsRange:int = 0, projectile:String = "", fireDelay:int = 0, firePower:int = 100, bank:Boolean = true) {
		
			super(object);
			
			_body = object as PlayObjectMovable;

			_speed = speed;
			_aggression = aggression;
			_weaponsRange = weaponsRange * weaponsRange;
			_projectile = projectile;
			_fireDelay = fireDelay;
			_firePower = firePower;
	
			_homePoint = _object.object.point.clone();
			
			if (bank) MotionObject(_object.simObject).bankAmount = 0.5;
			
			_object.simObject.addEventListener(CollisionEvent.COLLISION, onCollision, false, 0, true);
			
		}
		
		//
		//
		override public function see(p:PlayObject):void {
			
			super.see(p);
			
			if (_object == null || _object.deleted) {
				end();
				return;
			}
			
			if (p.object.symbolName == "player") {
				
				if (_player == null) _object.eventSound("see");
				_player = p;
				_playerNear = true;
				
			}
			
		}
		
		//
		//
		override public function update (e:Event):void {
			
			if (_ended || !_active || _body.locked || _body.dying) return;
			
			super.update(e);
			
			if (_body == null || _body.deleted) {
				end();
				return;
			}
			
			if (_playerNear && Math.floor(Math.random() * 20) == 10) _object.eventSound("random");
			
			if (_player == null || _playerNear == false) {
				
				if (_homePoint.x < _object.object.x) _body.moveLeft(_speed / 20);
				else if (_homePoint.x > _object.object.x) _body.moveRight(_speed / 20);
				
				if (_homePoint.y > _object.object.y) _body.moveUp(_speed / 20);
				else if (_homePoint.y < _object.object.y)  _body.moveDown(_speed / 20);	
				
			}
			
			if (_player != null && _player.deleted) {
				
				_player = null;
				_playerNear = false;
				
			} else if (_playerNear) {
				
				var sqdist:Number = Geom2d.squaredDistanceBetweenPoints(_object.object.point, _player.object.point);
				
				var xv:Number = Math.abs(MotionObject(_object.simObject).velocity.x);
				
				if (sqdist > 200000) {
							
					_player = null;
					_playerNear = false;
					_lastApproach = 0;
	
				} else {
						
					if (sqdist > 1000 + _weaponsRange * 0.5) {
						
						if (_object.playfield.map.canSee(_body, _player)) {
							
							if (_player.object.x - _player.object.width * 0.5 < _object.object.x) _body.moveLeft(_speed / 10);
							else if (_player.object.x + _player.object.width * 0.5 > _object.object.x) _body.moveRight(_speed / 10);
							
							if (_player.object.y + _player.object.height * 0.5 > _object.object.y) _body.moveUp(_speed / 20);
							else _body.moveDown(_speed / 20);
						
							_lastApproach = 0;
							
						}
						
					} else {
						
						if (sqdist < 1000 + _weaponsRange) {
							
							if (_player.object.x - _player.object.width * 0.5 > _object.object.x) _body.moveLeft(_speed / 20);
							else if (_player.object.x + _player.object.width * 0.5 < _object.object.x) _body.moveRight(_speed / 20);
							
							if (_weaponsRange > 0 && canAttack && _projectile.length > 0) {
								
								PlayObject.launchNew(_projectile, _object, null, _firePower, _player);
								
							}
							
						}
						
						if (_player.object.y + _player.object.height * 0.5 + 100 > _object.object.y) _body.moveUp(_speed / 40);
						else _body.moveDown(_speed / 40);
						
					}

				}
				
			}
				
		}
		
		//
		//
		public function get canAttack ():Boolean  {
			
			if (_fireDelay == 0 && (TimeStep.realTime - _lastAttack > (10 - _speed) * 200 && Math.random() * 100 < _aggression) ||
				_fireDelay > 0 && (TimeStep.realTime - _lastAttack > _fireDelay)) {
			
				_lastAttack = TimeStep.realTime;
				return true;
				
			}
			
			return false;
			
		}
		
		
		//
		//
		protected function onCollision (e:CollisionEvent):void {
			
			if (_player == null && e.collider.objectRef.symbolName == "player") {
				
				_player = _object.playfield.playObjects[e.collider];
				
			}
			
			if (_player != null && e.collider == _player.simObject && _weaponsRange == 0 && canAttack) {
				
				if (_object.object.y > _player.object.y) {
					
					_body.harm(_player as PlayObjectControllable, 5);
					_lastAttack = TimeStep.realTime;
					ObjectFactory.effect(_object, "biteeffect", true, 1000, e.contactPoint);
					_object.eventSound("collide");
				
				}
				
			}
			
		}
		
		//
		//
		override public function end():void {
			
			_body = null;
			_player = null;
			if (_object != null && _object.simObject != null) _object.simObject.removeEventListener(CollisionEvent.COLLISION, onCollision);
			_object = null;
			_homePoint = null;
			
			super.end();
			
		}
		
	}
	
}