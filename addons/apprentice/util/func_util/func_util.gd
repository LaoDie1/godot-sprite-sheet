#============================================================
#    Func Util
#============================================================
# - datetime: 2022-12-08 23:25:09
# - version: 4.x
#============================================================
## 执行回调方法工具类
##
##这个工具类可以通过调用执行 execute 开头的方法以方便的执行一些比较另类的操作。
##[br]
##[br]比如控制节点向目标移动一小段距离：
##[codeblock]
##var duration = 1.0
##var speed = 50.0
##FuncUtil.execute_fragment_process(duration, func():
##    var dir = node.global_position.direction_to(target.global_position)
##    node.global_position += dir * speed * get_physics_process_delta_time()
##)
##[/codeblock]
class_name FuncUtil


class BaseExecutor extends Timer:
	var _finished_callable := Callable()
	
	func _add_to_scene(to: Node = null):
		if to == null:
			to = Engine.get_main_loop().current_scene
		to.add_child(self)
	
	func _finished():
		if _finished_callable.is_valid():
			_finished_callable.call()
	
	# 设置完成回调
	func set_finish_callback(callable: Callable):
		_finished_callable = callable
		return self
	
	# 直接清除
	func kill():
		stop()
		queue_free()


#============================================================
#  执行对象
#============================================================
# 普通的按照线程执行的对象
class ExecutorObject extends BaseExecutor:
	
	var _finish : bool = false
	var _condition : Callable = func(): return true
	var _callable : Callable
	
	func _init(callable: Callable, process_callback):
		_callable = callable
		self.timeout.connect(_finished, Object.CONNECT_ONE_SHOT)
		self.process_callback = process_callback
	
	func _ready():
		self.start()
		self.set_process(process_callback == Timer.TIMER_PROCESS_IDLE)
		self.set_physics_process(process_callback == Timer.TIMER_PROCESS_PHYSICS)
	
	func _process(delta):
		if _condition.call() and _callable.is_valid():
			_callable.call()
	
	func _physics_process(delta):
		if _condition.call() and _callable.is_valid():
			_callable.call()
	
	func _finished():
		super._finished()
		_finish = true
		self.queue_free()
		set_physics_process(false)
		set_process(false)
	
	## 设置执行完成时调用的方法
	func set_finish_callback(callable: Callable) -> ExecutorObject:
		super.set_finish_callback(callable)
		return self
	
	## 设置执行时中断并结束的条件
	func set_finish_condition(condition: Callable) -> ExecutorObject:
		_condition = condition
		return self


#============================================================
#  一次性回调
#============================================================
class _OnceTimer extends BaseExecutor:
	var _callable: Callable
	
	func _init(callable: Callable, delay_time: float, over_time: float):
		_callable = callable
		self.timeout.connect(_finished)
		self.one_shot = true
		ready.connect(func():
			if delay_time > 0:
				await get_tree().create_timer(delay_time).timeout
			callable.call()
			if over_time > 0:
				self.wait_time = over_time
				self.start(over_time)
			else:
				self.timeout.emit()
		)
	
	func _finished():
		super._finished()
		self.queue_free()
	


#============================================================
#  间隔执行计时器
#============================================================
class _IntermittentTimer extends BaseExecutor:
	
	var _amount_left : int = 0
	var _max_count: int = 0
	var _callable : Callable
	
	## 剩余数量
	func get_amount_left() -> int:
		return _amount_left
	
	## 获取最大次数
	func get_max_amount() -> int:
		return _max_count
	
	func _init(callable: Callable, max_count: int) -> void:
		assert(max_count > 0, "最大执行次数必须超过0！")
		_max_count = max_count
		_amount_left = max_count
		_callable = callable
		self.timeout.connect(func():
			callable.call()
			if _amount_left > 1:
				_amount_left -= 1
			else:
				self.stop()
				_finished()
				self.queue_free()
		)
	
	## 执行结束调用这个回调
	func set_finish_callback(callable: Callable) -> _IntermittentTimer:
		_finished_callable = callable
		return self


#============================================================
#  列表时间间隔执行计时器
#============================================================
class _IntermittentListTimer extends BaseExecutor:
	var _list = []
	var _callable : Callable = Callable()
	var _executed_callable: Callable = Callable()
	var _time : float
	
	func _init(list: PackedFloat64Array, callable: Callable):
		_list = list
		_list.reverse()
		_callable = callable
		self.timeout.connect(func():
			if not _callable.is_null():
				_callable.call()
			if not _executed_callable.is_null():
				_executed_callable.call(_time)
			self._next()
		)
	
	func _enter_tree():
		_next()
	
	func _next() -> void:
		if _list.size() == 0:
			_finished()
			self.queue_free()
			return
		
		_time = _list.pop_back()
		if _time == 0:
			self.timeout.emit()
		else:
			self.start(_time)
	
	# 每个时间执行结束之后，调用这个方法，这个方法需要有一个 [float] 参数接收这次结束的时间的值
	func executed(callable: Callable) -> _IntermittentListTimer:
		_executed_callable = callable
		return self
	
	## 完全执行结束调用这个回调
	func set_finish_callback(callable: Callable) -> _IntermittentListTimer:
		super.set_finish_callback(callable)
		return self
	


#============================================================
#  自定义
#============================================================
##  执行一次功能
##[br]
##[br][code]over_time[/code]  结束时间
##[br][code]callable[/code]  执行的方法
##[br][code]delay_time[/code]  延迟执行调用方法
##[br][code]to_node[/code]  添加到这个节点上
##[br][code]return[/code]  返回执行对象
static func execute_once(
	over_time: float, 
	callable: Callable, 
	delay_time: float = 0.0, 
	to_node: Node = null
) -> _OnceTimer:
	var timer := _OnceTimer.new(callable, delay_time, over_time)
	(to_node if to_node else Engine.get_main_loop().current_scene).add_child(timer)
	return timer


## 执行一个片段线程
##[br]
##[br][code]duration[/code]  持续时间
##[br][code]callable[/code]  每帧执行的回调方法，这个方法无需参数和返回值
##[br][code]params[/code]  传入方法的参数值
##[br][code]process_callback[/code]  线程类型：0 physics 线程 [constant Timer.TIMER_PROCESS_PHYSICS]
##，1 普通 process 线程 [constant Timer.TIMER_PROCESS_IDLE]
##[br]
##[br][code]return[/code]  返回执行对象
static func execute_fragment_process(
	duration: float,
	callable: Callable, 
	process_callback : int = Timer.TIMER_PROCESS_PHYSICS,
	to_node: Node = null
) -> ExecutorObject:
	var timer := ExecutorObject.new(callable, process_callback)
	timer.wait_time = duration
	if not is_instance_valid(to_node):
		timer._add_to_scene()
	else:
		to_node.add_child.call_deferred(timer)
	return timer


##  间歇性执行
##[br]
##[br][code]interval[/code]  间隔执行时间
##[br][code]count[/code]  执行次数
##[br][code]callable[/code]  回调方法
##[br][code]immediate_execute_first[/code]  立即执行第一个
##[br]
##[br][code]return[/code]  返回执行的计时器
static func execute_intermittent(
	interval: float, 
	count: int, 
	callable: Callable,
	immediate_execute_first: bool = false, 
	process_callback : int = Timer.TIMER_PROCESS_PHYSICS,
	to_node: Node = null
) -> _IntermittentTimer:
	if immediate_execute_first:
		count -= 1
	var timer := _IntermittentTimer.new(callable, count)
	timer.wait_time = interval
	timer.one_shot = false
	timer.autostart = true
	timer.process_callback = process_callback
	timer._add_to_scene(to_node)
	if interval > 0:
		if immediate_execute_first:
			timer.timeout.emit()
	else:
		for i in count:
			timer.timeout.emit()
	return timer


##  根据传入的时间列表间歇执行
##[br]
##[br][code]interval_list[/code]  时间列表
##[br][code]callable[/code]  回调方法
##[br][code]return[/code]  返回间歇执行计时器对象
static func execute_intermittent_by_list(
	interval_list: PackedFloat64Array, 
	callable: Callable = Callable()
) -> _IntermittentListTimer:
	var timer =  _IntermittentListTimer.new(interval_list, callable)
	timer.one_shot = true
	timer.autostart = false
	timer._add_to_scene()
	return timer


## 没别的，仅仅调用一下这个回调。
##[br]
##[br][code]callable[/code]  回调方法
##[br][code]deferred[/code]  延迟调用
##[br][code]deferred_value[/code]  延迟调用返回的结果值
static func execute(callable: Callable, deferred : bool = false, deferred_value = null):
	if not deferred:
		return callable.call()
	else:
		callable.call_deferred()
		return deferred_value


## 执行功能。如果节点不在场景树中，则在进入场景后执行功能，否则直接执行功能
static func execute_or_enter_tree(node: Node, callable: Callable):
	if not node.is_inside_tree():
		node.tree_entered.connect(callable, Object.CONNECT_ONE_SHOT)
	else:
		callable.call()


## 节点在场景中时信号才连接调用一次这个 [Callable]，如果节点已经在场景中，则直接调用 [Callable] 方法
##[br]
##[br][code]signal_or_node[/code]  信号或节点对象
##[br][code]callable[/code]  回调方法
##[br][code]params[/code]  传入的参数
static func call_once_in_tree(signal_or_node, callable: Callable, params: Array = []):
	if signal_or_node is Node:
		signal_or_node = signal_or_node.tree_entered
	else:
		assert(signal_or_node is Signal, "signal_or_node 参数必须是 Node 或 Signal 类型")
	var node = signal_or_node.get_object()
	if not node.is_inside_tree():
		signal_or_node.connect(func():
			callable.callv(params)
		, Object.CONNECT_ONE_SHOT)
	else:
		callable.callv(params)


## 节点初始化后设置属性
##[br]
##[br][code]node[/code]  设置属性的节点
##[br][code]property_to_node_path_map[/code]  属性对应的要获取的节点的路径。key为属性，
##value 为节点路径
##[br][code]get_path_to_node[/code]  根据这个节点获取这个路径节点，如果为 null，则默认为
##node 参数值
##[br][code]set_node_callable[/code]  如何获取设置节点的方法，这个方法需要有两个参数，第一个参数为
##[String] 类型接收属性名，第二个为 [NodePath] 类型，用于接收节点路径，返回一个 [Node] 类型的数据
static func set_node_propertys_by_path_map(
	node: Node, 
	property_to_node_path_map: Dictionary, 
	get_path_to_node: Node = null
):
	if get_path_to_node == null:
		get_path_to_node = node
	
	# 获取设置节点的方法
	var set_node_callable = func(property: String, node_path: NodePath):
		if node[property] == null:
			node.set(property, get_path_to_node.get_node_or_null(node_path))
	
	call_once_in_tree(node.tree_entered, func():
		var node_path : NodePath
		for prop in property_to_node_path_map:
			node_path = property_to_node_path_map[prop]
			# 获取节点设置属性
			set_node_callable.call(prop, node_path)
	)


##  根据节点名设置属性
##[br]
##[br][code]node[/code]  设置属性的节点
##[br][code]node_path_list[/code]  节点路径列表，如果有这个节点名称的属性，则进行设置
##[br][code]get_path_to_node[/code]  根据这个节点获取这个路径的节点，如果为 null，则默认为
##target_node 参数值
static func set_node_propertys_by_node_name(
	target_node: Node, 
	node_path_list: PackedStringArray, 
	get_path_to_node: Node = null
):
	call_once_in_tree(target_node.tree_entered, func():
		var prop_to_node_path_map := {}
		var prop : String
		for node_path in node_path_list:
			prop = str(node_path).get_file().replace("%", "")
			if prop in target_node:
				prop_to_node_path_map[prop] = node_path
			else:
				printerr(target_node, " 节点中没有这个属性：", prop)
		set_node_propertys_by_path_map(target_node, prop_to_node_path_map, get_path_to_node)
	)


##  设置带有前缀的属性的唯一名节点。（唯一节点名为这个属性去掉前缀后的名称）
##[br]
##[br][code]node[/code]  设置属性的节点
##[br][code]prefix[/code]  属性前缀
static func set_unique_node_propertys_by_prefix(
	node: Node,
	prefix: String, 
	get_path_to_node: Node = null
):
	call_once_in_tree(node.tree_entered, func():
		# 获取这个前缀的属性名
		var property_list = (node.get_property_list()
			.filter(func(data): return data['usage'] == PROPERTY_USAGE_SCRIPT_VARIABLE and data['name'].begins_with(prefix))
			.map(func(data): return data['name'] )
		)
		var prop_to_node_path_map = {}
		for prop in property_list:
			prop_to_node_path_map[prop] = "%" + prop.trim_prefix(prefix)
		if get_path_to_node == null:
			get_path_to_node = node
		var node_path
		for property in prop_to_node_path_map:
			node_path = prop_to_node_path_map[property]
			node[property] = get_path_to_node.get_node(node_path)
	)


##  根据前缀 find_node 设置节点属性
##[br]
##[br][code]node[/code]  设置属性的节点
##[br][code]prefix[/code]  属性前缀
##[br][code]get_path_to_node[/code]  以节点获取节点路径，传入 [Node] 类型或是一个无参的返回类型为
##[Node] 类型的 [Callable]
static func set_node_propertys_by_prefix_find_node(
	node: Node,
	prefix: String, 
	get_path_to_node = null
):
	call_once_in_tree(node.tree_entered, func():
		# 获取这个前缀的属性名
		var property_list = (node.get_property_list()
			.filter(func(data): return data['usage'] == PROPERTY_USAGE_SCRIPT_VARIABLE and data['name'].begins_with(prefix))
			.map(func(data): return data['name'] )
		)
		var prop_to_node_path_map = {}
		for prop in property_list:
			prop_to_node_path_map[prop] = prop.trim_prefix(prefix)
		if get_path_to_node is Callable:
			get_path_to_node = get_path_to_node.call()
		get_path_to_node = get_path_to_node as Node
		
		# 设置属性
		var node_path
		for property in prop_to_node_path_map:
			node_path = prop_to_node_path_map[property]
			node.set(property, get_path_to_node.get_node(node_path))
	)


##  等待一帧调用这个方法
##[br]
##[br][code]callable[/code]  调用的方法
##[br][code]process_callback[/code]  线程类型，默认为 [constant Timer.TIMER_PROCESS_IDLE]
static func await_process_once(
	callable: Callable, 
	process_callback := Timer.TIMER_PROCESS_IDLE
) -> void:
	if process_callback == Timer.TIMER_PROCESS_IDLE:
		Engine.get_main_loop().process_frame.connect( callable, Object.CONNECT_ONE_SHOT )
	else:
		Engine.get_main_loop().physics_frame.connect( callable, Object.CONNECT_ONE_SHOT )


##  遍历列表
##[br]
##[br][code]list[/code]  列表
##[br][code]callable[/code]  回调方法，这个方法需要有个参数：
##[br] - idx  [int] 类型参数，用于接收索引
##[br] - item [Variant] 类型参数，用于接收这个索引的列表项的值
##[br][code]step[/code]  间隔步长，如果超过0则正序行，如果低于0则倒序执行
##[br] 比如扫描当前对象脚本下的所有 gd 文件
##[codeblock]
##var dir = ScriptUtil.get_object_script_path(self).get_base_dir()
##var files = FileUtil.scan_file(dir)
##FuncUtil.foreach(files, func(idx, file:String):
##    if file.get_extension() == "gd":
##        print(file, "\t", file.get_file())
##)
##[/codeblock]
static func foreach(list: Array, callable: Callable, step: int = 1) -> void:
	if step > 0:
		for i in range(0, list.size(), step):
			callable.call(i, list[i])
	elif step < 0:
		for i in range(list.size()-1, -1, step):
			callable.call(i, list[i])
	else:
		assert(false, "错误的 step 参数值，值不能为 0！")


## 循环遍历执行
##[br]
##[br][code]list[/code]  遍历的列表
##[br][code]callable[/code]  回调方法。这个方法主要可以设置参数的型，而普通for循环不能设置参数类型
static func forexec(list: Array, callable: Callable) -> void:
	for item in list:
		callable.call(item)


##  遍历字典。使用这个方法的好处是 callable 里的参数可以设置类型，参数有代码提示
##[br]
##[br][code]dict[/code]  字典数据
##[br][code]callable[/code]  回调方法。这个方法需要有两个参数，一个 key，一个 value
static func for_dict(dict: Dictionary, callable: Callable):
	for key in dict:
		callable.call( key, dict[key] )


## 遍历 rect。callable 方法需要有一个 Vector2 类型的参数的回调
static func for_rect(rect: Rect2, callable: Callable) -> void:
	for x in range(rect.position.x, rect.end.x):
		for y in range(rect.position.y, rect.end.y):
			callable.call(Vector2(x, y))

static func for_rect_x(rect: Rect2, callable: Callable) -> void:
	for x in range(rect.position.x, rect.end.x):
		callable.call(x)

static func for_rect_y(rect: Rect2, callable: Callable) -> void:
	for y in range(rect.position.y, rect.end.y):
		callable.call(y)


##  递归处理对象。要确保有归出的条件，返回空值进行归出，比如 [code]null, false, [], {}[/code]，否则只遍历一层就结束
##[br]
##[br][code]object[/code]  递归的对象列表
##[br][code]callable[/code]  这个方法用于接收要递归的对象，并返回下一个要递归的对象或数组。
##[br]遍历所有子节点：
##[codeblock]
##FuncUtil.recursion(self, func(node):
##    if node is Node2D:
##        print(node)
##    return node.get_children()
##)
##[/codeblock]
static func recursion(object, callable: Callable) -> void:
	var last = (object 
		if object is Array 
		else [object]
	)
	while true:
		var next_list = []
		if last:
			for i in last:
				var items = callable.call(i)
				if items:
					if items is Array:
						next_list.append_array(items)
					else:
						next_list.append(items)
			last = next_list
		else:
			break


## 合并字典
##[br]
##[br][code]from[/code]  数据来源
##[br][code]to[/code]  合并数据到这个字典上
##[br][code]callable[/code]  用于合并的方法。这个方法需要有 4 个参数：
##[br] - 一个 to_previous 参数接收这个 to_value 父级字典数据
##[br] - 一个 to_value 参数接收 to_previous 下的 from_key 值的数据
##[br] - 一个 from_key 接收可设置的数据的 key
##[br] - 一个 from_value 参数接收可设置的数据的 value 数据
##[br]
##[br]比如将字典 from 合并合并到字典 to 中：
##[codeblock]
##FuncUtil.merge_dict(from, to, func(to_previous: Dictionary, to_value, from_key, from_value):
##    if to_previous.has(from_key):
##        if to_previous[from_key] is Dictionary and from_value is Dictionary:
##            to_previous[from_key].merge(from_value)
##    else:
##        to_previous[from_key] = from_value
##)
##[/codeblock]
static func merge_dict(from: Dictionary, to: Dictionary, callable: Callable) -> void:
	var f = func(callback: Callable, to_previous: Dictionary, to_value, from_key, from_value):
		callable.call(to_previous, to_value, from_key, from_value)
		if from_value is Dictionary:
			for key in from_value:
				callback.call(
					callback, 
					to_value, 
					to_value.get(key) if to_value is Dictionary else null, 
					key, 
					from_value[key] 
				)
	
	for key in from:
		f.call(
			f, 
			to, 
			to.get(key) if to is Dictionary else null, 
			key, from[key]
		)


## 监听执行
##[br]
##[br][code]condition[/code]  执行结束条件方法
##[br][code]execute_callback[/code]  执行功能
##[br][code]finish_callable[/code]  执行结束时的回调
static func monitor(condition: Callable, execute_callback: Callable, finish_callable: Callable = Callable()):
	execute_fragment_process(INF, execute_callback ) \
	.set_finish_condition(condition) \
	.set_finish_callback(
		func():
			if finish_callable.is_valid():
				finish_callable.call()
	)


## 施加力
##[br]
##[br][code]init_vector[/code]  初始移动速度
##[br][code]attenuation[/code]  衰减速度
##[br][code]motion_callable[/code]  控制运动的回调。这个方法需要接收一个 [FuncApplyForceState] 类型的数据，
##利用里面的数据控制节点
##[br][code]target[/code]  执行功能的节点的依赖目标，如果这个目标死亡，则执行结束
##[br][code]duration[/code]  持续时间
static func apply_force(init_vector: Vector2, attenuation: float, motion_callable: Callable, target: Node2D = null, duration : float = INF):
	var state := FuncApplyForceState.new()
	state.speed = init_vector.length()
	state.update_velocity(init_vector)
	state.attenuation = attenuation
	
	# 控制运动
	var timer = DataUtil.get_ref_data(null)
	var delta = Engine.get_main_loop().root.get_physics_process_delta_time()
	timer.value = execute_fragment_process(duration, func():
		if attenuation > 0:
			state.speed = state.speed - attenuation
		if (
			state.finish
			or state.speed <= 0 
			or (target != null and not is_instance_valid(target))
		):
			timer.value.queue_free()
			return
		
		# 运动回调
		motion_callable.call(state)
		
	, Timer.TIMER_PROCESS_PHYSICS, target)


## 执行 Curve 曲线的比值的 tween
##[br]
##[br][code]curve[/code]  曲线资源对象。一般是创建一个 [Curve] 文件或使用对象的 [Curve] 类型的属性的值作为参数值
##[br][code]object[/code]  控制对象
##[br][code]property_path[/code]  控制属性
##[br][code]final_val[/code]  执行完到达的最终值
##[br][code]duration[/code]  执行时间
##[br][code]reverse[/code]  颠倒获取曲线值
##[br][code]init_val[/code]  初始值。一般 reverse 参数为 [code]true[/code] 时都要设置这个值
static func execute_curve_tween(curve: Curve, object: Object, property_path: NodePath, final_val: Variant, duration: float, reverse: bool = false, init_val = null):
	if init_val == null:
		init_val = object.get_indexed(property_path)
	else:
		object.set_indexed(property_path, init_val)
	
	var proxy = {
		"time": 0.0,
		"scene": Engine.get_main_loop().current_scene
	}
	if reverse:
		var init_y = curve.sample_baked(1)
		object.set_indexed(property_path, lerp(init_val, final_val, init_y))
		execute_fragment_process(duration, 
			func():
				proxy.time += proxy.scene.get_process_delta_time()
				var ratio = proxy.time / duration
				var y = curve.sample_baked(1.0 - ratio)
				object.set_indexed(property_path, lerp(init_val, final_val, y))
		, Timer.TIMER_PROCESS_IDLE
		, object if object is Node else Engine.get_main_loop().current_scene
		).set_finish_callback(
			func():
				var y : float = curve.sample_baked(0)
				object.set_indexed(property_path, lerp(init_val, final_val, y))
		)
		
	else:
		var init_y = curve.sample_baked(0)
		object.set_indexed(property_path, lerp(init_val, final_val, init_y))
		execute_fragment_process(duration, 
			func():
				proxy.time += proxy.scene.get_process_delta_time()
				var ratio = proxy.time / duration
				var y = curve.sample_baked(ratio)
				object.set_indexed(property_path, lerp(init_val, final_val, y))
		, Timer.TIMER_PROCESS_IDLE
		, object if object is Node else Engine.get_main_loop().current_scene
		).set_finish_callback(
			func():
				var y : float = curve.sample_baked(1)
				object.set_indexed(property_path, lerp(init_val, final_val, y))
		)


##  每帧不断地方法，直到条件为 [code]true[/code] 执行回调结束
##[br]
##[br][code]condition[/code]  执行条件
##[br][code]callback[/code]  回调方法
static func until(condition: Callable, callback: Callable):
	while condition.call():
		callback.call()
		await Engine.get_main_loop().process_frame

