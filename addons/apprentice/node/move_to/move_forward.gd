#============================================================
#	Move Forward
#============================================================
# @datetime: 2022-7-31 23:53:03
#============================================================

##  向前移动。根据这个节点的旋转方向发出移动向量信号
class_name MoveForward
extends Node2D


##  移动方向
signal moved_direction(direction: Vector2)


## 使用全局位置属性
@export 
var use_global_position := true : set=set_use_global_position
## 节点默认朝向
@export
var default_direction : Vector2 = Vector2.LEFT


var _rot : float = INF
var _dir : Vector2 = Vector2(0,0)
var _offset_rot : float = 0.0
var _p : String = "global_rotation"


#============================================================
#   SetGet
#============================================================
func set_use_global_position(value: bool) -> void:
	use_global_position = value
	_p = "global_rotation" if use_global_position else "rotation"


#============================================================
#   内置
#============================================================
func _ready():
	update_direction()


func _physics_process(delta):
	if _rot != self[_p]:
		update_direction()
	moved_direction.emit(_dir)


#============================================================
#   自定义 
#============================================================
##  更新方向 
func update_direction():
	_rot = self[_p]
	_dir = default_direction.rotated(self[_p])


