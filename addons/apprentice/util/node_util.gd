#============================================================
#	Node Util
#============================================================
# @datetime: 2022-7-31 18:31:44
#============================================================
class_name NodeUtil


static func get_physics_process_delta_time():
	return Engine.get_main_loop().current_scene.get_physics_process_delta_time()

static func get_process_delta_time():
	return Engine.get_main_loop().current_scene.get_process_delta_time()


##  扫描所有子节点
##[br]
##[br][code]parent_node[/code]  开始的父节点
##[br][code]filter[/code]  过滤方法。这个方法有一个参数用于接收传入的节点，如果返回 [code]true[/code]，则添加，否则不添加
##[br][code]return[/code]  返回扫描到的所有节点
static func get_all_child( parent_node: Node, filter := Callable() ) -> Array[Node]:
	var list : Array[Node] = []
	var _scan_all_node = func(_parent: Node, self_callable: Callable):
		if filter.is_null():
			for child in _parent.get_children():
				list.append(child)
		else:
			for child in _parent.get_children():
				if filter.call(child):
					list.append(child)
		for child in _parent.get_children():
			self_callable.call(child, self_callable)
	_scan_all_node.call(parent_node, _scan_all_node)
	return list


##  创建一个计时器
##[br]
##[br][code]time[/code]  倒计时时间
##[br][code]to[/code]  添加到的节点
##[br][code]callable[/code]  回调方法
##[br][code]return[/code]  返回创建的 [Timer] 计时器
static func create_timer(
	time: float, 
	to: Node = null, 
	callable: Callable = Callable(), 
	autostart : bool = false
) -> Timer:
	var timer := Timer.new()
	timer.wait_time = time
	if not callable.is_null():
		timer.timeout.connect(callable)
	if autostart:
		timer.autostart = true
	if to.is_inside_tree():
		to.add_child(timer)
	else:
		to.add_child.call_deferred(timer)
	return timer


##  创建一个一次性计时器
##[br]
##[br][code]time[/code]  时间
##[br][code]callable[/code]  回调方法
##[br][code]to[/code]  添加到这个节点上，如果为 null，则自动添加到当前场景
##[br][code]return[/code]  返回创建的 [Timer]
static func create_once_timer(time:float=1.0, callable:Callable=Callable(), to: Node = null) -> Timer:
	if to == null:
		if callable.is_valid():
			var object = callable.get_object() as Object
			if is_instance_valid(object) and object is Node:
				to = object
	if to == null:
		to = Engine.get_main_loop().current_scene
	
	var timer := create_timer(time, to, callable, true)
	timer.one_shot = true
	timer.timeout.connect(timer.queue_free)
	return timer


##  获取场景树
##[br]
##[br][code]return[/code]  返回场景树
static func get_tree() -> SceneTree:
	return Engine.get_main_loop().root.get_tree()


##  获取当前场景
##[br]
##[br][code]return[/code]  返回当前场景节点
static func get_current_scene() -> Node:
	return Engine.get_main_loop().current_scene

##  创建 Tween
static func create_tween() -> Tween:
	return get_tree().create_tween()

##  根据 Class 获取父节点
##[br]
##[br][code]node[/code]  开始节点
##[br][code]_class[/code]  祖父节点的类
##[br][code]return[/code]  返回符合的类的祖父节点
static func find_parent_by_class(node: Node, _class) -> Node:
	var p = node.get_parent()
	var root = node.get_tree().root
	while not is_instance_of(p, _class):
		p = p.get_parent()
		if p == root:
			return null
	return p


## 添加节点到当前场景
##[br]
##[br][code]node[/code]  要添加的节点
##[br][code]callable[/code]  节点信号调用的方法
##[br][code]signal_name[/code]  要连接到的这个节点的信号名
##[br][code]force_readable_name[/code]  强制设置可读性强的名称
##[br][code]internal[/code]  添加的节点的内部方式，详见 [Node] 节点中的 [enum Node.InternalMode] 枚举 
static func add_node_to_current_scene(
	node: Node, 
	callable: Callable= Callable(), 
	signal_name: StringName = &"ready", 
	force_readable_name: bool = false, 
	internal: int = 0
) -> Node:
	Engine.get_main_loop().current_scene.add_child.call_deferred(node, force_readable_name, internal)
	if not callable.is_null():
		node.connect(signal_name, callable, Object.CONNECT_ONE_SHOT)
	return node


##  添加节点到目标
##[br]
##[br][code]node[/code]  节点目标
##[br][code]to[/code]  添加到的节点上
##[br][code]callable[/code]  这个节点添加到场景上之后的回调
static func add_node(node: Node, to: Node, callable: Callable = Callable()) -> Node:
	if callable.is_valid():
		node.tree_entered.connect(callable, Object.CONNECT_ONE_SHOT)
	to.add_child.call_deferred(node)
	return node


##  添加节点列表到节点中
##[br]
##[br][code]to[/code]  要添加到的节点
##[br][code]node_list_or_callable[/code]  节点列表，或者返回类型为 [code]Array[Node][/code] 的 [Callable] 对象
##[br][code]force_readable_name[/code]  强制设置可读性强的名称
##[br][code]internal[/code]  添加的节点的内部方式，详见 [Node] 节点中的 [enum Node.InternalMode] 枚举 
static func add_node_by_list(
	to: Node, 
	node_list_or_callable, 
	force_readable_name: bool = false, 
	internal: int = Node.INTERNAL_MODE_DISABLED
) -> Array:
	var node_list 
	if node_list_or_callable is Callable:
		node_list = node_list_or_callable.call()
	elif node_list_or_callable is Array:
		node_list = node_list_or_callable
	else:
		assert(false, "错误的参数类型：node_list_or_callable > " + node_list_or_callable)
	for node in node_list:
		to.add_child(node, force_readable_name, internal)
	return node_list


## 实例化这个类型下的场景
##[br]
##[br][code]_class[/code]  类型
static func instance_class_scene(_class: Script) -> Node:
	var data = DataUtil.get_meta_dict_data("NodeUtil_instance_class_scene")
	if data.has(_class):
		return data[_class].instantiate()
	else:
		var path := _class.resource_path
		var ext := path.get_extension()
		var file = path.substr(0, len(path) - len(ext))
		
		var scene: PackedScene
		if FileAccess.file_exists(file + "tscn"):
			scene = load(file + "tscn") as PackedScene
		elif FileAccess.file_exists(file + "scn"):
			scene = load(file + "scn") as PackedScene
		else:
			printerr("这个类目录下没有相同名称的场景文件！")
			return null
		data[_class] = scene
		return scene.instantiate()


##  延迟移除
##[br]
##[br][code]node[/code]  移除节点
##[br][code]time[/code]  延迟时间
static func delay_free(node: Node, time: float):
	get_tree().create_timer(time).timeout.connect(node.queue_free)


##  添加节点到目标或添加到当前场景中
##[br]
##[br][code]node[/code]  添加的节点
##[br][code]to[/code]  添加到的目标，如果这个值不传入或为 [code]null[/code]，则默认添加到当前场景中
##[br][code]force_readable_name[/code]  添加的节点名称是否为可读的
##[br][code]internal[/code]  添加的节点的内部方式，详见 [Node] 节点中的 [enum Node.InternalMode] 枚举 
static func add_node_to_or_current_scene(
	node: Node, 
	to: Node = null, 
	force_readable_name: bool = false, 
	internal: int = 0
) -> void:
	if to:
		to.add_child(node, force_readable_name, internal)
	else:
		Engine.get_main_loop().current_scene.add_child(node, force_readable_name, internal)


##  节点是否在场景树中
##[br]
##[br][code]node[/code]  节点对象
static func is_inside_tree(node: Node) -> bool:
	return node is Node and node != null and node.is_inside_tree()


## 获取这个类型的子节点
static func find_child_by_class(parent: Node, type) -> Array[Node]:
	var list : Array[Node] = []
	for child in parent.get_children():
		if is_instance_of(child, type):
			list.append(child)
	return list


## 获取这个类型的第一个子节点
static func find_first_child_by_class(parent: Node, type) -> Node:
	var list = find_child_by_class(parent, type)
	if list.size() > 0:
		return list[0]
	return null


##  查找匹配这个名称的所有子节点
static func find_all_children_by_name(root: Node, pattern: String) -> Array[Node]:
	var regex = RegEx.new()
	regex.compile(pattern)
	
	var list : Array[Node] = []
	FuncUtil.recursion([root], func(node: Node):
		if regex.search(node.name):
			list.push_back(node)
		return node.get_children()
	)
	return list

##  查找匹配这个类型的所有子节点
##[br]
##[br][code]root[/code]  根节点
##[br][code]_class[/code]  类
static func find_all_children_by_class(root: Node, _class) -> Array[Node]:
	return get_all_child(root, func(node: Node): return is_instance_of(node, _class) )


## 从父节点中移除这个节点
static func remove_self(node: Node) -> bool:
	if node.is_inside_tree():
		node.get_parent().remove_child(node)
		return true
	return false

