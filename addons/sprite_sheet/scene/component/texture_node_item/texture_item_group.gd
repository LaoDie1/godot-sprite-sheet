#============================================================
#    Texture Item Group
#============================================================
# - author: zhangxuetu
# - datetime: 2023-05-28 22:53:19
# - version: 4.0
#============================================================
class_name SpriteSheetTextureItemGroup


signal selected(item_node: SpriteSheetTextureItem, state: bool)
signal right_clicked(item_node: SpriteSheetTextureItem)
signal double_clicked(item_node: SpriteSheetTextureItem)


var _data_list : Array[Dictionary] = []
var _can_handle_selected : Array = [true]
var _last_right_clicked_item_data : Dictionary


## 获取所有待处理数据
func get_data_list() -> Array[Dictionary]:
	return _data_list

## 获取所有的图片
func get_texture_list() -> Array[Texture2D]:
	var list = get_data_list().map(func(data): return data['texture'])
	return Array(list, TYPE_OBJECT, "Texture2D", null)

## 获取选中的节点的数据
func get_selected_data_list() -> Array[Dictionary]:
	var selected_list = get_data_list() \
		.filter(func(data): return data['selected'])
#	selected_list.sort_custom(func(a, b): a["node"].get_index() > b["node"].get_index() )
	return selected_list

## 获取选中的图片
func get_selected_texture_list() -> Array[Texture2D]:
	return Array(get_selected_data_list().map(func(data): return data['texture']), TYPE_OBJECT, "Texture2D", null)

## 获取选中的节点列表
func get_selected_node_list() -> Array[SpriteSheetTextureItem]:
	var list : Array[SpriteSheetTextureItem] = []
	list.append_array(get_selected_data_list().map(func(data): return data['node']))
	return list

## 获取节点列表
func get_item_node_list() -> Array[SpriteSheetTextureItem]:
	if _data_list.is_empty():
		return Array([], TYPE_OBJECT, "MarginContainer", SpriteSheetTextureItem)
	return Array(_data_list.map(func(data): return data['node']), TYPE_OBJECT, "MarginContainer", SpriteSheetTextureItem)


func add_item(item_node: SpriteSheetTextureItem) -> void:
	# 选中
	var data : Dictionary = item_node.get_data()
	_data_list.append(data)
	item_node.selected.connect(func(state: bool): 
		# 这个key 是用来筛选是否选中的节点的，所以发生改变时必须修改
		data['selected'] = state
		
		# 一帧内只触发一个选中的节点信号
		if not _can_handle_selected[0]:
			return
		_can_handle_selected[0] = false
		Engine.get_main_loop().process_frame.connect(func():
			_can_handle_selected[0] = true
		, Object.CONNECT_ONE_SHOT)
		
		# 如果选中多个，则不取消选中，改为只选中这一个
		if (not state 
			and not (Input.is_key_pressed(KEY_SHIFT) and Input.is_key_pressed(KEY_CTRL))
			and SpriteSheetUtil.has_mouse(item_node)
		):
			var selected_nodes = get_selected_node_list()
			selected_nodes.erase(item_node)
			if selected_nodes.size() > 0:
				for node in selected_nodes:
					node.set_selected(false)
				data['selected'] = true
				item_node.set_selected(true)
				return
		
		if state:
			self.selected.emit(item_node)
		
		# shift 键连选
		if Input.is_key_pressed(KEY_SHIFT):
			var indxs = get_selected_data_list().map(func(data): return (data['node'] as Node).get_index() )
			if not indxs.is_empty():
				var start_idx : int = indxs.min()
				var end_idx : int = indxs.max()
				for i in range(start_idx, end_idx+1):
					var item = _data_list[i]["node"] as SpriteSheetTextureItem
					item.set_selected(true)
		
		# ctrl 键多选，如果没有则会自动取消显示其他选中的项
		if not Input.is_key_pressed(KEY_CTRL) and not Input.is_key_pressed(KEY_SHIFT):
			var selected_node_list = get_selected_node_list()
			selected_node_list.erase(item_node)
			if not selected_node_list.is_empty():
				for selected_node in selected_node_list:
					selected_node.set_selected(false)
		
	)
	# 右键点击
	item_node.right_clicked.connect(func():
		item_node.set_selected(true)
#		item_popup_menu.popup(Rect2i( item_node.get_global_mouse_position(), Vector2i() ))
		_last_right_clicked_item_data = data
		self.right_clicked.emit(item_node)
	)
	# 双击
	item_node.double_clicked.connect(func(): 
		self.double_clicked.emit(item_node)
		# 发送之后修改完全部的点击状态，然后再把这个状态设置为未选中
		item_node.set_selected.call_deferred(false)
	)
	
	# 拖拽
	item_node.dragged.connect(func(callback_data_list: Array):
		var selected_data_list = _data_list.filter(func(d): return d['selected'])
		if selected_data_list.is_empty():
			selected_data_list.append(data)
		callback_data_list.clear()
		callback_data_list.append_array(selected_data_list)
	)
	
	# 移除
	item_node.removed.connect(func(): 
		_data_list.erase(data)
	)
