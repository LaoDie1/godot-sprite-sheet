#============================================================
#    Node Db
#============================================================
# - author: zhangxuetu
# - datetime: 2023-03-07 12:56:42
# - version: 4.x
#============================================================
## 场景节点中的对象进行记录
##
##用于方便获取对应类型的节点
class_name SceneNodeDb
extends Node


## 新的节点
##[br]
##[br][code]node[/code]  新增的节点
##[br][code]type[/code]  节点类型
signal newly_node(node, type)
## 移除掉的节点
##[br]
##[br][code]_class[/code]  移除的节点
##[br][code]return[/code]  节点类型
signal removed_node(node, type)


@export
var root : Node :
	set(v):
		root = v
		root.child_entered_tree.connect(_record_child_data)
		root.child_exiting_tree.connect(_remove_child_data)


var _script_extends_link_map : Dictionary =  DataUtil.get_meta_dict_data("SceneNodeDb_memeber_script_extends_link_map")

# 类对应的节点列表
var _class_to_nodes_map : Dictionary = {}
# 名称对应的点列表
var _name_to_nodes_map : Dictionary = {}


#============================================================
#  SetGet
#============================================================
func get_nodes_by_class(_class) -> Array[Node]:
	var id = _get_id(_class)
	return _class_to_nodes_map.get(id, Array([], TYPE_OBJECT, "Node", null))

func get_nodes_by_name(_name: StringName) -> Array[Node]:
	return _name_to_nodes_map.get(_name, Array([], TYPE_OBJECT, "Node", null))

func _get_id(_class):
	return hash(_class)

func get_first_node_by_class(_class) -> Node:
	var list = get_nodes_by_class(_class)
	if list.size() > 0:
		return list[0]
	return null

func get_first_node_by_name(_name: StringName) -> Node:
	var list = get_nodes_by_name(_name)
	if list.size() > 0:
		return list[0]
	return null



#============================================================
#  自定义
#============================================================
func _record_child_data(node: Node) -> void:
	if node.child_entered_tree.is_connected(_record_child_data):
		return
	node.child_entered_tree.connect(_record_child_data)
	
	# 节点类型及父类型
	var _classes = []
	var script = node.get_script()
	if script != null:
		_classes = DataUtil.get_value_or_set(_script_extends_link_map, script, func():
			var list = ScriptUtil.get_extends_link(script)
			return Array(list).map(func(path): return load(path))
		)
	
	var clist = ScriptUtil.get_extends_link_base(node.get_class())
	for c in clist:
		var base_class = ScriptUtil.get_built_in_class(c)
		_classes.append(base_class)
		
	
	# 这个类型的节点列表
	for _class in _classes:
		var id = _get_id(_class)
		var ctn_list = DataUtil.get_value_or_set(_class_to_nodes_map, id, func(): return Array([], TYPE_OBJECT, "Node", null))
		ctn_list.append(node)
		self.newly_node.emit(node, _class)
	
	# 这个名称的节点列表
	var ctn_list = DataUtil.get_value_or_set(_name_to_nodes_map, node.name, func(): return Array([], TYPE_OBJECT, "Node", null))
	ctn_list.append(node)


func _remove_child_data(node: Node) -> void:
	node.child_exiting_tree.connect(_record_child_data)
	
	# 节点类型及父类型
	var _classes = []
	var script = node.get_script()
	if script != null:
		_classes = DataUtil.get_value_or_set(_script_extends_link_map, script, func():
			var list = ScriptUtil.get_extends_link(script)
			return Array(list).map(func(path): return load(path))
		)
	
	# 这个类型的节点列表
	for _class in _classes:
		var id = _get_id(_class)
		var ctn_list = DataUtil.get_value_or_set(_class_to_nodes_map, id, func(): return Array([], TYPE_OBJECT, "Node", null))
		ctn_list.append(node)
		self.newly_node.emit(node, _class)
	
	# 这个类型的节点列表
	for _class in _classes:
		var id = _get_id(_class)
		var ctn_list = DataUtil.get_value_or_set(_class_to_nodes_map, id, func(): return Array([], TYPE_OBJECT, "Node", null))
		ctn_list.erase(node)
		self.removed_node.emit(node, _class)
	
	# 这个名称的节点列表
	var ctn_list = DataUtil.get_value_or_set(_name_to_nodes_map, node.name, func(): return Array([], TYPE_OBJECT, "Node", null))
	ctn_list.erase(node)


