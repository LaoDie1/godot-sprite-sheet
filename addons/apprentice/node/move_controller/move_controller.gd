#============================================================
#	Move Controller
#============================================================
# @datetime: 2022-5-18 20:44:32
#============================================================
## 移动控制器
##
## 连接 moved 信号实现控制方式，然后通过调用 move 开头的方法进行移动。
class_name MoveController
extends Node2D


## 移动状态发生改变
signal move_state_changed(state: bool)
## 方向发生改变
signal direction_changed(direction: Vector2)
## 已移动
signal moved(vector: Vector2)


## 移动速度
@export 
var move_speed : float = 100.0
## 加速度。只在调用 [method move_direction] 方法时执行加速度，最大速度为 [member move_speed]
@export_range(0.0, 60.0, 0.001, "or_greater")
var acceleration : float = 60.0
## 摩擦力。速度会根据摩擦力慢慢减慢，如果为0，则没有摩擦力，会一直向前滑行移动。
@export_range(0.0, 60.0, 0.001, "or_greater") 
var friction : float = 60.0


## 当前移动的移动向量
var motion_velocity := Vector2(0,0) :
	set(v):
		motion_velocity = v


# 实时移动速度
var _move_speed := 0.0
# 是否正在移动
var _moving := false :
	set(value):
		if _moving != value:
			_moving = value
			self.move_state_changed.emit(_moving)
# 最后一次移动方向
var _direction := Vector2(0,0)
# 上一帧移动方向
var _previous_direction := Vector2(0, 0)
var _last_move_vector : Vector2 = Vector2(0,0)


#============================================================
#   Set/Get
#============================================================
## 是否正在移动
func is_moving() -> bool:
	return _moving

## 获取移动的方向
func get_direction() -> Vector2:
	return _direction

## 获取当前移动速度
func get_current_move_speed() -> float:
	return _move_speed

func get_last_move_vector() -> Vector2:
	return _last_move_vector


#============================================================
#   内置
#============================================================
func _physics_process(delta):
	_move()


#============================================================
#   自定义
#============================================================
## 移动线程
func _move() -> void:
	# 移动向量
	motion_velocity = lerp(motion_velocity, _direction * _move_speed, acceleration * get_physics_process_delta_time() )
	self.moved.emit(motion_velocity)
	
	# 移动后
	_last_move_vector = motion_velocity
	motion_velocity = Vector2(0, 0)
	if _previous_direction == Vector2(0,0):
		_move_speed = lerpf(_move_speed, 0.0, friction * get_physics_process_delta_time())
	if _move_speed == 0.0:
		self._moving = false
	_previous_direction = Vector2(0,0)


## 更新状态，主要更新移动速度和移动状态
##[br]
##[br][code]dir[/code]  移动方向
func _update_state(dir: Vector2):
	if dir != Vector2(0,0):
		update_direction(dir)
		_move_speed = lerpf(_move_speed, move_speed, acceleration * get_physics_process_delta_time() )
		self._moving = true


## 更新方向
##[br]
##[br][code]dir[/code]  更新到的方向
func update_direction(dir: Vector2):
	if _direction != dir:
		_direction = dir
		self.direction_changed.emit(_direction)


## 根据方向移动 
##[br]
##[br][code]direction[/code]  移动的方向
func move_direction(direction: Vector2):
	_previous_direction = direction
	_update_state(direction)


## 根据向量移动 
##[br]
##[br][code]velocity[/code]  移动向量
func move_vector(velocity: Vector2):
	_update_state(velocity.normalized())
	motion_velocity = velocity

