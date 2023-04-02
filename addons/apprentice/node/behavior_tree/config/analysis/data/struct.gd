#============================================================
#    Struct
#============================================================
# - datetime: 2023-02-07 16:00:26
#============================================================
extends RefCounted


# 行为树根节点
var root : BTRoot
var node : Node

var parent_struct
var children_struct : Array = []

# 文档描述名称
var name : String
# 解析的字符串
var token : String
# 这一行的字符串
var line : String


# 执行方法的对象的类型
var do_object : Object
var do_type :
	set(v):
		do_type = v
		if do_type and do_object != null:
			do_object = do_type.new()
var method


#============================================================
#  自定义
#============================================================
func get_type():
	return node.get_script()

func get_method_object_type():
	if do_type == null:
		if do_object != null:
			do_type = do_object.get_script()
	return do_type

func get_object() -> Object:
	return do_object

func get_method() -> Callable:
	if method is Callable:
		return method
	if method is String:
		return Callable(do_object, method)
	return Callable()


