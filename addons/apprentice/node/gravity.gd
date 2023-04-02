#============================================================
#    Gravity
#============================================================
# - datetime: 2023-02-19 14:42:49
#============================================================
class_name Gravity
extends Node2D


signal gravitated(vector: Vector2)


## 当前重力值
@export
var gravity : float = 0.0
## 每秒的重力速度
@export_range(0, 1000, 0.001, "or_greater")
var gravity_speed : float = 0.0
## 最大达到的力速度
@export_range(0, 1000, 0.001, "or_greater")
var gravity_max : float = 0.0 
## 坠落方向
@export
var direction : Vector2 = Vector2.DOWN:
	set(v):
		direction = v.normalized()


var velocity : Vector2 = Vector2(0,0)


func _physics_process(delta: float) -> void:
	gravity += gravity_speed * delta
	velocity = (direction * gravity).limit_length( gravity_max )
	
	self.gravitated.emit(velocity)


func reset():
	velocity = Vector2(0, 0)


