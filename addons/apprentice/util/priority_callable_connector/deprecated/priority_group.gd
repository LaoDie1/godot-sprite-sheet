#============================================================
#    Priority Group
#============================================================
# - author: zhangxuetu
# - datetime: 2023-03-15 16:39:11
# - version: 4.0
#============================================================
## 调用这一组中的方法
class_name PriorityGroup


## 执行回调的数据
class ExecuteGroupData:
	# 这一批次执行的ID
	var group_id 
	
	# 参数，如果修改这个参数，在优先级之后的方法的参数会改为这个参数的值
	var params = []


## 连接时的信息
class ConnectGroupData:
	var group
	var callable: Callable 
	var queue : PriorityQueue



# 这一次调用的方法批次值
var _call_id = 0
# group 值对应的 Callable 队列
var _group_to_queue_map : Dictionary = {}
# 正在执行的组
var calling_group := {}
# 阻断继续执行的组
var _prevent_group := {}
# 组中上次的数据
var _last_group_data := {}


##  获取组中的数据
static func get_group_data(group) -> Dictionary:
	const KEY = "PriorityGroup_get_group_data"
	var data : Dictionary
	if Engine.has_meta(KEY):
		data = Engine.get_meta(KEY)
	else:
		data = {}
		Engine.set_meta(KEY, data)
	
	if data.has(group):
		return data[group]
	else:
		data[group] = {}
		return data[group]


## 是否正在调用
func is_calling(group) -> bool:
	return calling_group.has(group)


## 获取上次组中的数据，在每次调用 Callable 时的数据，用于对这个数据参数进行改变
func get_last_group_params(group) -> ExecuteGroupData:
	if _last_group_data.has(group):
		return _last_group_data[group] as ExecuteGroupData
	return null


##  添加优先级队列 [Callable]
##[br]
##[br][code]group[/code]  添加到的队列的组值
##[br][code]callable[/code]  回调方法
##[br][code]priority[/code]  优先级，值越小越先被调用
##[br]
##[br][code]return[/code]  返回连接ID
func add_callable(group, callable: Callable, priority: int = 0):
	var id = ",".join([hash(group), hash(callable)]).sha1_text()
	var group_data = get_group_data(group)
	if group_data.has(id):
		return null
	
	# 获取这个组的队列
	var queue : PriorityQueue
	if _group_to_queue_map.has(group):
		queue = _group_to_queue_map[group] as PriorityQueue
	else:
		queue = PriorityQueue.new()
		_group_to_queue_map[group] = queue
	
	# 添加 callable 到这个组的对列里
	queue.add_item(callable, priority)
	_last_group_data[group] = ExecuteGroupData.new()
	
	# 连接的数据
	var cgd = ConnectGroupData.new()
	cgd.queue = queue
	cgd.callable = callable
	cgd.group = group
	group_data[id] = cgd
	return id


##  移除连接优先级队列回调
##[br]
##[br][code]group[/code]  组值
##[br][code]callable[/code]  移除的会调用方法
##[br]
##[br][code]return[/code]  返回是否移除成功
static func remove_callable(group, id) -> bool:
	var group_data : Dictionary = get_group_data(group) as Dictionary
	if group_data.has(id):
		var data = group_data[id] as ConnectGroupData
		data.queue.remove_item(data.callable)
		group_data.erase(id)
		return true
	return false


## 调用这组 [Callable] 回调，如果想调用某个信号，则使用这个方法进行调用。
##[br]
##[br]示例，调用 property_changed 信号组中的所有的 [Callable]：
##[codeblock]
##priority_connector.call_group(self.property_changed, [Const.Property.HEALTH, 3])
##[/codeblock]
##[br]
##[br][code]group[/code]  对这个 group 的 [Callable] 进行调用
##[br][code]params[/code]  参数列表
func call_group(group, params: Array = []) -> void:
	var queue = _group_to_queue_map.get(group) as PriorityQueue
	if queue:
		calling_group[group] = null
		
		# 这一次执行的组
		_call_id += 1
		if _call_id == 0x7FFFFFFFFFFFFFFF:
			_call_id = 0
		
		var group_data := ExecuteGroupData.new()
		group_data.group_id = _call_id
		group_data.params = params
		_last_group_data[group] = group_data
		
		for item in queue.get_items():
			# 判断是否被阻断
			if _prevent_group.has(group):
				# 当前批次要被阻断时
				if _prevent_group[group] == group_data.group_id:
					_prevent_group.erase(group)
					# 退出循环不再执行后面连接的方法
					break
			item.callv(group_data.params)
		calling_group.erase(group)


## 阻断执行
func prevent(group) -> void:
	if calling_group.has(group):
		# 获取上次执行的组的ID
		var group_data := _last_group_data[group] as ExecuteGroupData
		# 记录当前这这个组的 ID 值
		_prevent_group[group] = group_data.group_id
	else:
		printerr(group, " 没有在执行")


## 替换组中的参数
func replace_params(group, params: Array):
	if _last_group_data.has(group):
		var group_data = _last_group_data[group] as ExecuteGroupData
		group_data.params = params
	else:
		printerr("没有这个 ", group, " 的数据")


