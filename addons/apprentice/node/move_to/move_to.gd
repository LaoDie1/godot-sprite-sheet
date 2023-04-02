#============================================================
#	Move To
#============================================================
# @datetime: 2022-7-31 12:59:58
#============================================================
## 移动到位置
class_name MoveTo
extends Node2D


## 准备移动到位置
signal ready_move(to_pos: Vector2)
## 到达位置
signal arrived
## 停止
signal stopped
## 移动到方向
signal moved(direction: Vector2)


## 在这个距离内则视为到达了位置
@export 
var arrive_distance := 100.0 : 
	set(v):
		arrive_distance = v
		_arrived_squared_distance = pow(arrive_distance, 2)
## 更新移动方向的间隔时间
@export
var update_direction_time := 1.0:
	set(v):
		update_direction_time = v
		_update_timer.wait_time = update_direction_time


var _update_timer := Timer.new()
@onready
var _arrived_squared_distance := pow(arrive_distance, 2)
@onready 
var _to_pos : Vector2 = global_position
var _last_rot := INF
var _to_dir := Vector2.ZERO


#============================================================
#   SetGet
#============================================================
## 是否正在执行
func is_running() -> bool:
	return is_physics_processing()

## 获取目的地的方向
func get_to_direction() -> Vector2:
	return _to_dir

## 获取移动到的位置
func get_move_to_position() -> Vector2:
	return _to_pos

##  获取剩余距离
func get_distance_left() -> float:
	return global_position.distance_to(_to_pos)


#============================================================
#   内置
#============================================================
func _enter_tree() -> void:
	if Engine.is_editor_hint():
		set_physics_process(false)
		set_process(false)
	if arrive_distance == 0:
		push_error("MoveTo 节点的 'arrive_distance' 属性为 0，这很有可能会导致到达位置抖动")


func _ready() -> void:
	set_physics_process(false)
	_update_timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	_update_timer.timeout.connect(_update_move_direction)
	add_child(_update_timer)


func _physics_process(delta):
	if global_position.distance_squared_to(_to_pos) > _arrived_squared_distance:
		if _last_rot != global_rotation:
			_update_move_direction()
		self.moved.emit(_to_dir)
	
	else:
		set_physics_process(false)
		_update_timer.stop()
		arrived.emit()


#============================================================
#   自定义
#============================================================
#  更新移动方向
func _update_move_direction() -> void:
	_last_rot = global_rotation
	_to_dir = global_position.direction_to(_to_pos)


##  移动到位置
##[br]
##[br][code]global_pos[/code]  移动到的位置
func to(global_pos: Vector2) -> void:
	if global_pos != _to_pos:
		_to_pos = global_pos
		_update_move_direction()
		_update_timer.start()
		set_physics_process(true)
		self.ready_move.emit(_to_pos)


##  停止
func stop() -> void:
	_to_pos = global_position
	if is_physics_processing():
		set_physics_process(false)
		_update_timer.stop()
		self.stopped.emit()

