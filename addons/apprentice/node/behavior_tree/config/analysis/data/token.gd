#============================================================
#    Token
#============================================================
# - datetime: 2023-02-07 15:35:36
#============================================================
extends RefCounted


class MeanItem:
	# 这个 token 名称
	var name
	# 创建的类
	var type
	# 这个类初始化的时候的属性
	var init_prop : Dictionary = {}
	
	func create_node() -> Node:
		var node = type.new() as Node
		if init_prop:
			ObjectUtil.set_object_property(node, init_prop)
		return node
	
	func _to_string() -> String:
		return JsonUtil.object_to_string(self)
	


var mean : Array = []:
	set(v):
		mean = []
		
		var add_mean = func(dict: Dictionary):
			var name = dict['name']
			var mean_item = JsonUtil.dict_to_object(dict, MeanItem) as MeanItem
			mean.push_back(mean_item)
			_token_to_mean[name] = mean_item
		
		for i in v:
			var names = i['name']
			
			if names is String:
				add_mean.call(i)
				
			elif names is Array:
				var mean_item : MeanItem 
				for name in names:
					i['name'] = name
					add_mean.call(i)
			else:
				printerr("mean 中的 name 类型错误")
var _token_to_mean : Dictionary = {}


func get_mean_by_token(token: String) -> MeanItem:
	return _token_to_mean.get(token) as MeanItem

func has_type(type: String) -> bool:
	return _token_to_mean.get(type) != null


func _init(data: Dictionary):
	ObjectUtil.set_object_property(self, data)

func _to_string() -> String:
	return JsonUtil.object_to_string(self)

