#============================================================
#    StateNode
#============================================================
# - datetime: 2022-12-01 12:48:31
#============================================================
## 状态节点
class_name StateNode
extends Node


## 进入当前状态
signal entered_state(data: Dictionary)
## 退出当前状态
signal exited_state
## 状态发生切换。[code]previous[/code]上个状态名称，[code]current[/code]当前状态名，
##[code]data[/code]当前状态进入时传入的数据
signal state_changed(previous: StringName, current: StringName, data: Dictionary)


## 自动启动第一个子状态
@export
var auto_start : bool = false


var _name_to_state_map : Dictionary = {}
var _state_to_name_map : Dictionary = {}
var _current_state : StringName = &"":
	set(v):
		if _current_state != v:
			_current_state = v
			if not self.is_inside_tree(): await ready
			set_physics_process(_current_state != &"")
var _last_enter_data : Dictionary = {}


var __readied = self.ready.connect( func():
	for child in get_children():
		if child is StateNode:
			register_state(child.name, child)
	
	set_physics_process(false)
	
	if auto_start:
		if _name_to_state_map.is_empty():
			await Engine.get_main_loop().process_frame
		if not _name_to_state_map.is_empty():
			var first = _name_to_state_map.keys()[0]
			start(first)
#		else:
#			push_error(self, "没有子状态，自动启动失败")
	
, Object.CONNECT_ONE_SHOT)


#============================================================
#  SetGet
#============================================================
## 添加状态
##[br]
##[br][code]state[/code]  状态名
##[br][code]node[/code]  指定的状态节点
##[br][code]return[/code]  返回添加的状态
func add_state(state: StringName, node: StateNode = null) -> StateNode:
	if node == null:
		node = StateNode.new()
	register_state(state, node)
	node.name = state
	add_child.call_deferred(node, true)
	if self.is_inside_tree() and not is_running():
		start(state)
	return node

## 添加多个状态节点
func add_states(list: Array) -> Array[StateNode]:
	var nodes : Array[StateNode] = []
	for state in list:
		nodes.append(add_state(state))
	return nodes

## 获取状态
func get_state(idx: int) -> StringName:
	return _name_to_state_map.keys()[idx]

## 获取子级状态节点
func get_state_node(state: StringName) -> StateNode:
	return _name_to_state_map.get(state) as StateNode

## 获取当前执行的子级状态名称
func get_current_state() -> StringName:
	return _current_state

## 获取当前状态节点
func get_current_state_node() -> StateNode:
	return get_state_node(get_current_state()) if _current_state else null

## 退出当前状态
func exit_current_state() -> void:
	if get_current_state() != &"":
		get_current_state_node().exit_state()
		_current_state = &""

## 注册状态
func register_state(state: StringName, node: StateNode) -> void:
	if _name_to_state_map.has(state):
		printerr("已经添加过 ", state, " 状态")
	_name_to_state_map[state] = node
	_state_to_name_map[node] = state

## 获取进入这个状态时的数据
func get_last_enter_data() -> Dictionary:
	return _last_enter_data

func is_running() -> bool:
	return _current_state != &""


#============================================================
#  内置
#============================================================
func _physics_process(delta: float) -> void:
	# 执行当前状态的线程
	get_current_state_node()._state_process(delta)



#============================================================
#  可重写
#============================================================
func _enter_state(data: Dictionary):
	pass


func _exit_state():
	pass


func _state_process(delta: float):
	pass


#============================================================
#  自定义
#============================================================
## 进入状态
func enter_state(data: Dictionary) -> void:
	_last_enter_data = data
	_enter_state(data)
	self.entered_state.emit(data)
	if _current_state != &"":
		set_physics_process(true)
	


## 退出状态
func exit_state() -> void:
	_exit_state()
	self.exited_state.emit()
	set_physics_process(false)


## 启动状态机
func start(state: String, data: Dictionary = {}) -> void:
	assert(not _name_to_state_map.is_empty(), "没有添加子状态！")
	if _name_to_state_map.has(state):
		get_state_node(state).enter_state(data)
		_current_state = state
	else:
		push_error(self, "没有这个状态！state = ", state)


## 切换状态
func trans_to(state: StringName, data: Dictionary = {}) -> void:
	assert(_current_state != &"", "状态机还未启动！")
	if _name_to_state_map.has(state):
		var previous_state = _current_state
		get_state_node(previous_state).exit_state()
		
		_current_state = state
		get_state_node(state).enter_state(data)
		self.state_changed.emit( previous_state, state, data )
		
	else:
		push_error(self, "没有这个状态！state = ", state)


## 父节点切换状态
func parent_trans_to(state: StringName, data: Dictionary = {}) -> void:
	get_parent().trans_to(state, data)

