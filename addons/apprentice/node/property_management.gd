#============================================================
#    Property Management
#============================================================
# - datetime: 2022-11-23 19:35:39
#============================================================
## 属性管理
class_name PropertyManagement
extends Node


##  数据发生改变
##[br]
##[br][code]property[/code]  数据的 ID
##[br][code]previous[/code]  改变前的数据值
##[br][code]current[/code]  当前的数据值
signal property_changed(property, previous, current)
## 新添加数据
signal newly_added_property(property, value)
## 移除了数据
signal removed_property(property, value)


# 属性对应的值
var _property_to_value_map : Dictionary = {}
# 属性发生改变时的回调方法
var _property_changed_callback_map : Dictionary = {}


#============================================================
#  SetGet
#============================================================
##  获取所有数据，属性对应的值
func get_property_map() -> Dictionary:
	return _property_to_value_map

## 监听指定属性。如果这个属性发生改变，则会调用这个方法。这个方法回调需要有两个参数，一个 previous
##接收上一次的值，一个 current 获取当前的值
func listen_property(property, callback: Callable):
	get_monitor_callback(property).append(callback)

## 获取监听属性的回调列表
func get_monitor_callback(property) -> Array:
	if _property_changed_callback_map.has(property):
		return _property_changed_callback_map.get(property) as Array
	else:
		_property_changed_callback_map[property] = []
		return _property_changed_callback_map[property] as Array

##  设置属性值
##[br]
##[br][code]force_change[/code]  强制进行修改
func set_property(property, value, force_change: bool = false):
	if _property_to_value_map.has(property):
		var _tmp_value = _property_to_value_map.get(property)
		if _tmp_value != value or force_change:
			_property_to_value_map[property] = value
			for callback in get_monitor_callback(property):
				callback.call(_tmp_value, value)
			self.property_changed.emit(property, _tmp_value, value)
	else:
		_property_to_value_map[property] = value
		for callback in get_monitor_callback(property):
				callback.call(null, value)
		self.newly_added_property.emit(property, value)

##  获取属性值
##[br]
##[br][code]default[/code]  如果没有这个属性时返回的默认值
func get_property(property, default = null):
	return _property_to_value_map.get(property, default)

##  是否存在有这个属性
func has_property(property) -> bool:
	return _property_to_value_map.has(property)

##  添加数据
func add_property(property, value):
	if value is float or value is int:
		set_property(property, _property_to_value_map.get(property, 0) + value )
	else:
		set_property(property, value, true)

##  减去数据
func sub_property(property, value):
	if value is float or value is int:
		set_property(property, _property_to_value_map.get(property, 0) - value )

##  移除数据
func remove_property(property):
	if _property_to_value_map.has(property):
		removed_property.emit(property, _property_to_value_map[property])
		_property_to_value_map.erase(property)

## 取出属性
func take_property(property, value, default = null):
	if has_property(property):
		var v = get_property(property, 0)
		# 如果值为数字，则减去取出的值
		if v is float or v is int:
			if v < value:
				value = v 
			sub_property(property, value)
			return value
		
		# 如果不是数字，则直接取出数据，并设置这个属性为 null
		else:
			set_property(property, default)
			return v
	return default


## 获取数据并转为 [bool] 类型
func get_as_bool(property, default = false) -> bool:
	return bool(_property_to_value_map.get(property, default))

## 获取数据并转为 [int] 类型
func get_as_int(property, default = 0) -> int:
	return int(_property_to_value_map.get(property, default))

## 获取数据并转为 [float] 类型
func get_as_float(property, default = 0.0) -> float:
	return float(_property_to_value_map.get(property, default))

## 获取数据并转为 [String] 类型
func get_as_string(property, default = "") -> String:
	return str(_property_to_value_map.get(property, default))

## 获取数据并转为 [Array] 类型
func get_as_array(property, default = []) -> Array:
	return Array(_property_to_value_map.get(property, default))

## 获取数据并转为 [Dictionary] 类型
func get_as_dictionary(property, default = {}) -> Dictionary:
	return Dictionary(_property_to_value_map.get(property, default))
