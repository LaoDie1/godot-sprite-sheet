#============================================================
#    Objects
#============================================================
# - datetime: 2023-02-07 15:42:42
#============================================================
extends RefCounted


class DoMethodItem:
	var object : Object
	var name : String = ""
	var type = BaseDoNode
	var method
	var init_prop : Dictionary = {}
	
	# 执行上下文方法，用户接收到上下文，即可对内容进行操作
	# 这个上下文方法需要传入一个 Dictionary 类型的数据
	# 这个数据包含所需要的所有内容
	var context: Callable = func(context: Dictionary): pass
	
	func get_object(depend: Object = null):
		if object == null:
			if method is Callable and method.is_valid():
				object = method.get_object()
			if object == null:
				if type is String:
					object = ClassDB.instantiate(type)
				else:
					object = type.new()
				if object is RefCounted:
					ObjectUtil.ref_target(object, depend)
		return object
	
	func get_method(depend: Object = null) -> Callable:
		if method is Callable:
			return method
		if method is String:
			return Callable(get_object(depend), method)
#			printerr( ScriptUtil.get_object_script_path(self), " 获取方法对象时出现错误！" )
		return Callable()
	
	
	func _to_string():
		return JsonUtil.object_to_string(self)
	


var readable_name: bool = false
var add_to_scene : bool = true
var do_method : Array = [] :
	set(v):
		do_method = []
		for i in v:
			_add_do_item(i)
var _name_to_do_method : Dictionary = {}

var match_node_list : Array = []


#============================================================
#  内置
#============================================================
func _init(data: Dictionary):
	ObjectUtil.set_object_property(self, data)
	for node in match_node_list:
		var script = ScriptUtil.get_object_script(node)
		var do_item_data = {}
		for method_data in script.get_script_method_list():
			do_item_data['object'] = node
			do_item_data['name'] = method_data["name"]
			do_item_data['type'] = script
			do_item_data['method'] = Callable(node, method_data["name"])
			_add_do_item(do_item_data)


func _to_string() -> String:
	return JsonUtil.object_to_string(self)


#============================================================
#  自定义
#============================================================
func _add_do_item(dict: Dictionary):
	var desc_name = dict['name']
	if not _name_to_do_method.has(desc_name):
		var do_method_item := JsonUtil.dict_to_object(dict, DoMethodItem) as DoMethodItem
		do_method.append(do_method_item)
		# 添加到映射
		_name_to_do_method[desc_name] = do_method_item


func get_do_method(desc_name: String) -> DoMethodItem:
	desc_name = desc_name.strip_edges()
	return _name_to_do_method.get(desc_name) as DoMethodItem


func add_struct_node(node:Node, name: String, token: String, to: Node):
	if readable_name:
		name = name.c_escape()
		if name != "":
			node.name = name
		else:
			node.name = token
	to.add_child(node, readable_name)
	node.owner = to.owner

