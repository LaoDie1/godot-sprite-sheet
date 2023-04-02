#============================================================
#    Object Util
#============================================================
# - datetime: 2023-02-05 22:00:57
#============================================================
class_name ObjectUtil


## 引用对象，防止 RefCount 没有引用后被删除
class RefObject:
	extends Object
	
	var value
	
	func _init(value: Object) -> void:
		self.value = value



#============================================================
#  自定义
#============================================================
## 引用目标对象，防止引用丢失而消失。用在 [RefCounted] 类型的对象
##[br]
##[br]指定依赖象，如果对象消失，则引用的这个对象也随之消失
static func ref_target(object: RefCounted, depend: Object = null):
	if depend == null:
		depend = RefObject.new(object)
	const key = "__ObjectUtil_ref_target_data"
	if depend.has_meta(key):
		var list = depend.get_meta(key) as Array
		list.append(object)
	else:
		var list = [object]
		depend.set_meta(key, list)


## 删除对象
static func queue_free(object: Object) -> void:
	if is_instance_valid(object):
		if object is Node:
			object.queue_free()
		else:
			Engine.get_main_loop().queue_delete(object)


##  对象是否是这个类
##[br]
##[br][code]object[/code]  判断的对象
##[br][code]class_type[/code]  类
static func object_equals_class(object: Object, class_type) -> bool:
	return object != null and is_instance_of(get_object_class(object), class_type)


##  设置对象的属性
##[br]
##[br][code]object[/code]  对象的属性
##[br][code]prop_data[/code]  属性数据
##[br][code]setter_callable[/code]  设置属性的方法回调，默认直接对象进行赋值，这个方法需要有
##2 个参数，分别于接收设置的属性和设置的值，默认方法回调为：
##[codeblock]
##func(property, value):
##    if property in object:
##        object[property] = value
##[/codeblock]
static func set_object_property(
	object: Object, 
	prop_data: Dictionary, 
	setter_callable : Callable = Callable()
) -> void:
	if not setter_callable.is_valid():
		setter_callable = func(property, value):
			if property in object:
				object[property] = value
	
	for prop in prop_data:
		setter_callable.call(prop, prop_data[prop])


##  合并数组
##[br]
##[br][code]to[/code]  合并到这个数组
##[br][code]list[/code]  数组
static func merge_array(to: Array, list: Array) -> Array:
	to.append_array(list)
	return to


##  获取对象的类
static func get_object_class(object: Object):
	if object:
		if object is Script:
			return object
		if object.get_script() != null:
			return object.get_script()
		return ScriptUtil.get_built_in_class (object.get_class())
	return &""


##  实例化类场景
##[br]
##[br][code]_class[/code]  这个脚本下的相同脚本名称的场景
##[br][code]return[/code]  返回实例化后的场景
static func instance_class_scene(_class: Script) -> Node:
	var data = DataUtil.get_meta_dict_data("ObjectUtil_instance_scene_script_scene_map")
	var scene = DataUtil.get_value_or_set(data, _class, func():
		var path = ScriptUtil.get_object_script_path(_class).get_basename() + ".tscn"
		if FileAccess.file_exists(path):
			return load(path)
		push_error("没有 ", _class, " 类的场景")
		return null
	) as PackedScene
	if scene:
		return scene.instantiate()
	return null

