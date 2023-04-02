#============================================================
#    State Graph
#============================================================
# - author: zhangxuetu
# - datetime: 2023-03-13 10:05:29
# - version: 4.x
#============================================================
## 状态图
class_name StateGraph
extends Node


const ROOT_STATE = "__root__"


signal state_entered(state: StringName, data: Dictionary)
signal state_exited(state: StringName)
signal state_changed(previous: StringName, current: StringName, data: Dictionary)


# 状态名称对应的状态的数据
var _name_to_states_data : Dictionary = {}
# 进入这个状态后，状态每帧执行的回调方法
var _state_process_list : Dictionary = {}
# 当前进入的节点的状态名列表
var _entered_state : Array[StringName] = []
# ID 对应的数据
var _id_to_data : Dictionary = {}
# 当前状态
var _current_state : StringName


class StateData:
	# 这个状态的名称
	var name : StringName
	# 父状态名称
	var parent : StringName
	
	var node : StateNode
	var state_process : Array[Callable] = []



#============================================================
#  SetGet
#============================================================
func _get_state_process_list(state_name: StringName) -> Array:
	return _state_process_list.get(state_name, [])

func _register_state(state_name:String, state_node: StateNode) -> StateData:
	# 存储数据
	var state_data = StateData.new()
	state_data.name = state_name
	state_data.node = state_node
	state_node.entered_state.connect( func(data): 
		self._entered_state.append(state_name)
		self._current_state = state_name
		self.state_entered.emit( state_name, data )
	)
	state_node.exited_state.connect( func(): 
		# 子状态退出
		var snode = get_state_node(state_name)
		snode.exit_current_state()
		
		self._entered_state.erase(state_name) 
		self.state_entered.emit( state_name )
	)
	state_node.state_changed.connect(func(previous, current, data):
		Log.info([owner, previous, "->", current, data ])
		self.state_changed.emit(previous, current, data)
	)
	_name_to_states_data[state_name] = state_data
	return state_data


func get_state_data(state_name: StringName) -> StateData:
	return _name_to_states_data[state_name]

func get_state_node(state_name: StringName) -> StateNode:
	return get_state_data(state_name).node

func has_state(state_name: StringName) -> bool:
	return _name_to_states_data.has(state_name)

##  添加状态
##[br]
##[br][code]state_name[/code]  状态名
##[br][code]parent[/code]  添加到这个状态下
##[br][code]return[/code]  返回添加的状态节点
func add_state(state_name: StringName, parent: StringName = &"") -> StateNode:
	if has_state(state_name):
		printerr("已经存在有 ", state_name, " 状态！")
		return
	
	if parent == &"":
		parent = ROOT_STATE
	var parent_state_node = get_state_node(parent)
	var state_node : StateNode = parent_state_node.add_state(state_name)
	
	var state_data = _register_state(state_name, state_node)
	state_data.parent = parent
	
	return state_node

func get_root() -> StateNode:
	return get_state_node(ROOT_STATE)

## 返回当前执行的状态名
func get_current_states() -> Array[StringName]:
	return _entered_state

func get_current_state() -> StringName:
	if _entered_state.is_empty():
		return &""
	return _entered_state.back()

##  状态是否在执行中
func is_running(state_name: StringName) -> bool:
	assert(state_name != &"", "状态名不能为空")
	return get_current_states().has(state_name)


#============================================================
#  内置
#============================================================
func _init():
	var state_node = StateNode.new()
	_register_state(ROOT_STATE, state_node)
	state_node.auto_start = true
	add_child(state_node)


func _ready():
	FuncUtil.recursion(self, func(object):
		if object is StateNode:
			_register_state(object.name, object)
		return object.get_children()
	)


func _physics_process(delta):
	var result
	for state_name in _entered_state:
		for callable in get_state_data(state_name).state_process:
			result = callable.call()
			if result:
				trans_to(result)
	


#============================================================
#  自定义
#============================================================

##  添加这个状态执行时调用的线程
##[br]
##[br][code]state_name[/code]  状态名
##[br][code]callable[/code]  回调方法。如果返回状态名，则自动切换到对应状态
##[br][code]return[/code]  返回连接的ID
func listen_process(state_name: StringName, callable: Callable) -> String:
	var id = DataUtil.generate_id([state_name, callable])
	_id_to_data[id] = [state_name, callable]
	get_state_data(state_name).state_process.append(callable)
	return id


##  监听登录状态
##[br]
##[br][code]state_name[/code]  状态名
##[br][code]callable[/code]  登录回调方法。这个方法需要有一个 [Dictionary] 参数接收登录数据
##[br][code]return[/code]  返回连接的ID
func listen_enter(state_name: String, callable: Callable) -> String:
	var id = DataUtil.generate_id([state_name, callable])
	_id_to_data[id] = [state_name, callable]
	get_state_data(state_name).node.entered_state.connect(callable)
	return id


##  监听退出状态
##[br]
##[br][code]state_name[/code]  状态名
##[br][code]callable[/code]  登录回调方法。这个方法没有回调
##[br][code]return[/code]  返回连接的ID
func listen_exit(state_name: String, callable: Callable) -> String:
	var id = DataUtil.generate_id([state_name, callable])
	_id_to_data[id] = [state_name, callable]
	get_state_data(state_name).node.exited_state.connect(callable)
	return id


## 断开监听
func disconnect_listen(id: String) -> bool:
	if _id_to_data.has(id):
		var data = _id_to_data[id]
		var state_name = data[0]
		var callable = data[1]
		get_state_data(state_name).state_process.erase(callable)
		_id_to_data.erase(id)
		return true
	return false


##  切换到这个状态
##[br]
##[br][code]state_name[/code]  执行的状态的状态名
##[br][code]data[/code]  进入时传入的数据
func trans_to(state_name: StringName, data: Dictionary = {}) -> void:
	if state_name == &"":
		return
	if is_running(state_name):
		printerr("已经在执行这个状态：state = ", state_name)
		return
	
	# 查找这个状态的所有父级状态
	var states = []
	var tmp = state_name
	while true:
		var state_data = get_state_data(tmp)
		states.append(tmp)
		tmp = state_data.parent
		if tmp == ROOT_STATE:
			break
	
	# 从上到下进行切换到状态
	states.reverse()
	for state in states:
		var state_data = get_state_data(state)
		var parent_node = get_state_node(state_data.parent)
		if parent_node.get_current_state() != &"":
			parent_node.trans_to(state, {} if state_name != state else data)
		else:
			parent_node.start(state_name, {} if state_name != state else data)
		
	

