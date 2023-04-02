#============================================================
#    Behavior Tree Root
#============================================================
# - datetime: 2022-09-14 01:05:47
#============================================================

## 行为树根节点。只会执行第一个 bt 节点，所以一般下面会添加一个 [Selector] 节点
@icon("../icon/FBehaviorTreeRoot.png")
class_name BTRoot
extends Node

# 数据发生改变
signal data_changed(property, previous, current)


enum ProcessCallback {
	PHYSICS = Timer.TIMER_PROCESS_PHYSICS,
	IDLE = Timer.TIMER_PROCESS_IDLE,
}


##  这个行为树是否执行
@export
var enable : bool = true :
	set(v):
		enable = v
		__update_process()
## 线程执行方式
@export
var process_callback : ProcessCallback = ProcessCallback.PHYSICS :
	set(v):
		process_callback = v
		__update_process()


var _delta := 0.0
var _data := {}

var _leafs := []
var _first : Node



#============================================================
#  扫描子节点
#============================================================
class Scanner:
	# 扫描所有子孙节点
	static func _scan(node: Node, list: Array, condition: Callable):
		list.append_array(node.get_children().filter(condition))
		for child in node.get_children():
			_scan(child, list, condition)
	
	static func scan(node: Node, condition: Callable) -> Array:
		var list = []
		_scan(node, list, condition)
		return list


#============================================================
#  SetGet
#============================================================
##  用于子节点获取执行线程的间隔时间
func get_delta_time() -> float:
	return _delta

func get_property(property, default = null):
	return _data.get(property, default)

func set_property(property, value):
	if _data.get(property) != value:
		var previous = _data.get(property)
		_data[property] = value
		self.data_changed.emit(property, previous, value)


#============================================================
#  内置
#============================================================
func _enter_tree():
	var base_script = DataUtil.get_meta_data("__behavior_tree_BTBase_script", func(): 
		return load(ScriptUtil.get_object_script_path(self).get_base_dir().path_join("bt_base.gd"))
	)
	# 扫描筛选出带有 bt_root 属性的节点
	_leafs = Scanner.scan(self, func(node: Node): return is_instance_of(node, base_script) )
	for child in _leafs:
		if "bt_root" in child:
			child.bt_root = self
	__update_process()
	
	for child in get_children():
		if is_instance_of(child, base_script):
			_first = child
			break
	


func _ready():
	__update_process()
	_first = _leafs.front()


func _process(delta):
	_delta = delta
	_first._task()


func _physics_process(delta):
	_delta = delta
	_first._task()


#============================================================
#  自定义
#============================================================
func __update_process():
	set_physics_process(false)
	set_process(false)
	if not Engine.is_editor_hint():
		if process_callback == 0:
			set_physics_process(enable) 
		else:
			set_process(enable)


