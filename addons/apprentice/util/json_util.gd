#============================================================
#	Json Util
#============================================================
#  Json 数据转换器
#============================================================
# @datetime: _to_0_to__to_-4-_to_0 01:50:_to_4
#============================================================

##  转换 JSON 数据
class_name JsonUtil


##  根据字典数据设置对象所有属性
static func set_property_by_dict(dict: Dictionary, object: Object) -> void:
	if dict.size() > 0 and object:
		for property in dict:
			# 对象存在这个属性则设置
			if property in object:
				object.set(property, dict[property])


##  字典转换为 Object 对象
##[br]
##[br][code]dict[/code]  字典数据
##[br][code]class_[/code]  Class类或脚本
static func dict_to_object(dict: Dictionary, class_) -> Object:
	var object = class_.new()
	set_property_by_dict(dict, object)
	return object


##  对象转换为字典
static func object_to_dict(object, all: bool = false) -> Dictionary:
	if not is_instance_valid(object) or object.get_script() == null:
		return {}
	var data : Dictionary = {}
	var value
	var property_list : Array
	if not all:
		property_list = object.get_script().get_script_property_list()
	else:
		property_list = object.get_property_list()
	for prop in property_list:
		value = object.get(prop['name'])
		if value:
			data[prop['name']] = value
	return data


## 对象转为符串
static func object_to_string(object: Object, all: bool = false) -> String:
	return str(object_to_dict(object, all))


##  对象转为 JSON 数据
static func object_to_json(object: Object, indent: String = "", sort_keys: bool = true, full_precision: bool = false) -> String:
	return JSON.stringify(object_to_dict(object), indent, sort_keys, full_precision)


##  Json 转为对象 
##[br]
##[br][code]_class[/code]  转换成的对象类型
static func json_to_object(json: String, _class) -> Object:
	var j = JSON.new()
	if j.parse(json) == OK:
		return dict_to_object(j.get_data(), _class)
	return null


## 格式化输出
static func print_stringify(data, indent: String = "", sort_keys: bool = true, full_precision: bool = false) -> void:
	if data is Object:
		data = object_to_dict(data)
	
	print(JSON.stringify(data, indent, sort_keys, full_precision))


## 字典叠加数据
##[br]
##[br][code]origin_data[/code]  原始数据
##[br][code]from[/code]  要添加的数据
##[br][code]handle_value[/code]  对值数据进行处理的回调方法。这个方法需要有个参数，一个 key 接收当前叠加的数据的键，
##一个 value 用于接收当前叠加的据的值
static func dict_add(origin_data: Dictionary, from: Dictionary, handle_value := func(k, v): return v) -> Dictionary:
	origin_data = origin_data.duplicate(true)
	var value
	for key in from:
		if origin_data.has(key):
			value = from[key]
			if ((value is int or value is float) 
				and (origin_data[key] is int or origin_data[key] is float)
			):
				origin_data[key] += handle_value.call(key, value)
	origin_data.merge(from, false)
	return origin_data


