#============================================================
#    Group
#============================================================
# - author: zhangxuetu
# - datetime: 2023-03-23 00:16:36
# - version: 4.0
#============================================================
## 组别管理
class_name Group


#============================================================
#  SetGet
#============================================================
static func _get_group_data(group) -> Dictionary:
	var data = DataUtil.get_meta_dict_data("Group__get_data")
	return DataUtil.get_value_or_set(data, group, func(): {})

static func _get_node_groups(node: Node) -> Array:
	var data = DataUtil.get_meta_dict_data("Group__node_groups")
	return DataUtil.get_value_or_set(data, node, func(): [])


#============================================================
#  自定义
#============================================================
## 节点添加到这个组中
static func add(group, node: Node):
	assert(group == null, "组不能为空")
	if not node.tree_entered.is_connected(add):
		node.tree_entered.connect(add.bind(group, node))
		node.tree_exited.connect(remove.bind(group, node))
		_get_group_data(group)[node] = null
		_get_node_groups(node).append(group)


## 节点从这个组中移除
static func remove(group, node: Node):
	if node.tree_entered.is_connected(add):
		node.tree_entered.disconnect(add)
		node.tree_exited.disconnect(remove)
		_get_group_data(group).erase(node)
		_get_node_groups(node).erase(group)


## 节点是否在这个组中
static func is_in(group, node: Node) -> bool:
	return _get_group_data(group).has(node)


## 获取这个组中的所有节点
static func get_nodes(group) -> Array[Node]:
	return Array(_get_group_data(group).keys(), TYPE_OBJECT, "Node", null)


##  调用节点的方法
##[br]
##[br][code]group[/code]  组别
##[br][code]method[/code]  调用的方法
##[br][code]arg_arry[/code]  传入的参数
static func call_method(group, method: StringName, arg_arry: Array = []):
	for node in get_nodes(group):
		node.callv(method, arg_arry)


##  过滤这个组别的节点
##[br]
##[br][code]group[/code]  组别
##[br][code]filter_method[/code]  过滤条件方法，这个方法需要有一个 [Node] 类型参数判断是符合所需的节点，并返回 
##[bool] 值，如果没有返回值，则默认为 [code]false[/code]
##[br][code]return[/code]  返回符合过滤条件的节点
static func filter(group, filter_method: Callable) -> Array[Node]:
	var list : Array[Node] = []
	for node in get_nodes(group):
		if filter_method.call(node):
			list.append(node)
	return list



