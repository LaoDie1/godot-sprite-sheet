#============================================================
#    Data Management
#============================================================
# - datetime: 2022-11-23 19:35:39
#============================================================
## 数据管理
##
##通过 [member get_id] 获取 [Dictionary] 类型的数据指定的几个 key 生成的 id，然后加这个物品的数据
class_name DataManagement
extends Node


##  数据发生改变
##[br]
##[br] - [code]id[/code]  数据的 ID
##[br] - [code]previous[/code]  改变前的数据值
##[br] - [code]current[/code]  当前的数据值
signal data_changed(id, previous, current)
## 新添加数据
signal newly_added_data(id, data)
## 移除了数据
signal removed_data(id, data)


# id 对应的数据映射
var _id_to_data_map : Dictionary = {}
# 数据ID的回调列表映射
var _id_monitor_callback_map : Dictionary = {}


#============================================================
#  SetGet
#============================================================
##  获取所有数据，属性对应的值
func get_data_map() -> Dictionary:
	return _id_to_data_map


##  初始化设置数据
##[br]
##[br][code]data[/code]  设置的数据。[member get_data_map] 保存的数据调用这个方法实现数据加载.
func init_data(data: Dictionary):
	for id in data:
		set_data(id, data[id])


## 监听指定id的数据。如果这个 id 的数据发生改变或新增，则会调用这个方法。这个方法回调需要有两个参数，一个 previous
##接收上一次的值，一个 current 获取当前的值
func monitor_data(id, callback: Callable):
	get_monitor_callback(id).append(callback)


## 获取监听回调列表
func get_monitor_callback(id) -> Array:
	return DataUtil.get_value_or_set(_id_monitor_callback_map, id, func(): 
		return []
	)


## 根据所给数据和应 key 生成数据的 id
##[br]
##[br][code]data[/code]  数据
##[br][code]keys[/code]  数据中的key
##[br][code]return[/code]  返回数据中这些 key 对应 value 列表的 hash 值作为 id
static func get_id(data: Dictionary, keys : Array) -> String:
	var values = []
	for key in keys:
		values.append(hash(data.get(key)))
	return PackedByteArray(values).hex_encode()


## 查找数据
##[br]
##[br][code]condition[/code]  符合条件方法。这个方法需要有一个参接收每个数据，并判断是否符合要查找的数据，
##并返回 [bool] 类型的数据
##[br][code]return[/code]  返回所有符合条件的数据
func find_data(condition: Callable) -> Array:
	var list : Array = []
	var data
	for key in _id_to_data_map:
		data = _id_to_data_map[key]
		if condition.call(data):
			list.append(data)
	return list


##  设置属性值
##[br]
##[br][code]force_change[/code]  强制进行修改，这会发出 [signal data_changed] 信号
func set_data(id, value, force_change: bool = false):
	if _id_to_data_map.has(id):
		var _tmp_value = _id_to_data_map.get(id)
		if _tmp_value != value or force_change:
			_id_to_data_map[id] = value
			for callback in get_monitor_callback(id):
				callback.call(_tmp_value, value)
			self.data_changed.emit(id, _tmp_value, value)
	else:
		_id_to_data_map[id] = value
		for callback in get_monitor_callback(id):
			callback.call(null, value)
		self.newly_added_data.emit(id, value)


##  获取属性值
##[br]
##[br][code]default[/code]  如果没有这个属性时返回的默认值
func get_data(id, default = null):
	return _id_to_data_map.get(id, default)


##  是否存在有这个属性
func has_data(id) -> bool:
	return _id_to_data_map.has(id)


## 添加数据并自动获取设置 id
##[br]
##[br][code]value[/code]  数据值
##[br][code]keys[/code]  从这几个key中获取的数据生成id，如果没有，则默认获取所有数据生成id
func add_data_auto_id(value: Dictionary, keys: Array = []):
	if keys.is_empty():
		keys = value.keys()
	var id = get_id(value, keys)
	add_data(id, value)
	return id


##  添加数据
func add_data(id, value):
	if value is float or value is int:
		set_data(id, _id_to_data_map.get(id, 0) + value )
	else:
		set_data(id, value, true)


##  减去数据并自动获取设置 id。参数描述与 [method add_data_auto_id] 相同
func sub_data_auto_id(value: Dictionary, keys: Array = []):
	if keys.is_empty():
		keys = value.keys()
	var id = get_id(value, keys)
	sub_data(id, value)
	return id


##  减去数据
func sub_data(id, value):
	if value is float or value is int:
		set_data(id, _id_to_data_map.get(id, 0) - value )


##  移除数据
func remove_data(id):
	if _id_to_data_map.has(id):
		self.removed_data.emit(id, _id_to_data_map[id])
		_id_to_data_map.erase(id)


## 获取数据并转为 [bool] 类型
func get_data_as_bool(id, default = false) -> bool:
	return bool(_id_to_data_map.get(id, default))


## 获取数据并转为 [int] 类型
func get_data_as_int(id, default = 0) -> int:
	return int(_id_to_data_map.get(id, default))
