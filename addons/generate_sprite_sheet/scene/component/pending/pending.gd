#============================================================
#    Pending
#============================================================
# - author: zhangxuetu
# - datetime: 2023-03-31 08:38:06
# - version: 4.0
#============================================================
# 待处理图片管理
@tool
class_name GenerateSpriteSheet_Pending
extends PanelContainer


signal item_selected(data: Dictionary)
signal item_right_clicked(data: Dictionary)
signal item_double_clicked(data: Dictionary)
signal previewed(texture: Texture2D)
signal exported_texture(texture_list: Array[Texture2D])


const ITEM_SCENE = preload("item.tscn")
const ITEM_SCRIPT = preload("item.gd")

enum ImagePopupItem {
	PREVIEW,
	EXPORT_SELECTED_IMAGE,
	REMOVE,
}

@onready var item_container = %item_container
@onready var item_popup_menu = %item_popup_menu
@onready var group_dialog = %group_dialog
@onready var group_name_edit = %group_name_edit
@onready var panel_popup_menu = %panel_popup_menu
@onready var prompt_label = %prompt_label
@onready var export_selected_dialog = %export_selected_dialog


var _data_list : Array[Dictionary] = []
var _last_right_clicked_item_data : Dictionary


#============================================================
#  SetGet
#============================================================
func get_config_data() -> Dictionary:
	return GenerateSpriteSheetUtil.get_config_data("GenerateSpriteSheet_Pending")


## 获取所有待处理数据
func get_data_list() -> Array[Dictionary]:
	return _data_list


## 获取所有的图片
func get_texture_list() -> Array[Texture2D]:
	var list = get_data_list().map(func(data): return data['texture'])
	return Array(list, TYPE_OBJECT, "Texture2D", null)


## 获取选中的节点的数据
func get_selected_data_list() -> Array[Dictionary]:
	var selected_list = get_data_list().filter(func(data): return data['selected'])
#	selected_list.sort_custom(func(a, b): a["node"].get_index() > b["node"].get_index() )
	return selected_list

## 获取选中的图片
func get_selected_texture_list() -> Array[Texture2D]:
	return Array(get_selected_data_list().map(func(data): return data['texture']), TYPE_OBJECT, "Texture2D", null)


## 获取选中的节点列表
func get_selected_node_list() -> Array[ITEM_SCRIPT]:
	var list : Array[ITEM_SCRIPT] = []
	list.append_array(get_selected_data_list().map(func(data): return data['node']))
	return list


#============================================================
#  内置
#============================================================
func _ready():
	item_popup_menu.clear()
	var keys = ImagePopupItem.keys()
	item_popup_menu.add_item(keys[ImagePopupItem.PREVIEW], ImagePopupItem.PREVIEW)
	item_popup_menu.add_item(keys[ImagePopupItem.EXPORT_SELECTED_IMAGE], ImagePopupItem.EXPORT_SELECTED_IMAGE)
	item_popup_menu.add_separator()
	item_popup_menu.add_item(keys[ImagePopupItem.REMOVE], ImagePopupItem.REMOVE)
	item_popup_menu.add_separator()
	
	panel_popup_menu.clear()
	panel_popup_menu.add_item("CREATE_EMPTY_IMAGE")
	
	# 加载上次缓存数据
	var config = get_config_data()
	const KEY = "data_list"
	var data_list = config.get(KEY, [])
	for data in data_list:
		add_data(data)
	if _data_list.is_empty():
		_data_list.append_array(data_list)
	config[KEY] = _data_list
	
	prompt_label.visible = _data_list.is_empty()



func _can_drop_data(at_position, data):
	return (data is Dictionary
		and data.has("type")
		and data['type'] == GenerateSpriteSheetUtil.DragType.FileTree
	)


func _drop_data(at_position, data):
	var data_list = data['data']
	for d in data_list:
		if d['path_type'] == GenerateSpriteSheet_FileTree.PathType.FILE:
			add_data({
				"texture": GenerateSpriteSheetUtil.load_image(d.path),
				"path": d.path,
			})


func _gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				cancel_all_selected()
				
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				panel_popup_menu.popup(Rect2i(get_global_mouse_position(), Vector2i()))
		


#============================================================
#  自定义
#============================================================
func add_data(data: Dictionary):
	data = data.duplicate()
	_data_list.append(data)
	
	assert(data.has("texture"), "必须要含有 texture key 的数据")
	var texture_rect := ITEM_SCENE.instantiate() as ITEM_SCRIPT
	texture_rect.custom_minimum_size = Vector2(64, 64)
	item_container.add_child(texture_rect)
	prompt_label.visible = false
	data['node'] = texture_rect
	data['selected'] = false
	
	var texture = data.get('texture') as Texture2D
	if texture == null or texture.get_image().is_empty():
		data['texture'] = ImageTexture.create_from_image(Image.create(1, 1, false, Image.FORMAT_BPTC_RGBA))
	
	texture_rect.set_data(data)
	
	# 选中
	texture_rect.selected.connect(func(state: bool): 
		data['selected'] = state
		
		if state:
			self.item_selected.emit(data)
			
			# shift 键连选
			if Input.is_key_pressed(KEY_SHIFT):
				var indxs = get_selected_data_list().map(func(data): return (data['node'] as Node).get_index() )
				var start_idx = indxs.min()
				var end_idx = indxs.max()
				
				for i in range(start_idx, end_idx+1):
					var item = _data_list[i]["node"] as ITEM_SCRIPT
					item.set_selected(true)
			
			# ctrl 键多选，如果没有则会自动取消显示其他选中的项
			if not Input.is_key_pressed(KEY_CTRL) and not Input.is_key_pressed(KEY_SHIFT):
				var selected_node_list = get_selected_node_list()
				selected_node_list.erase(texture_rect)
				if not selected_node_list.is_empty():
					for selected_node in selected_node_list:
						selected_node.set_selected(false)
			
	)
	# 右键点击
	texture_rect.right_clicked.connect(func():
		item_popup_menu.popup(Rect2i( get_global_mouse_position(), Vector2i() ))
		texture_rect.set_selected(true)
		_last_right_clicked_item_data = data
		self.item_right_clicked.emit(data)
	)
	# 双击
	texture_rect.double_clicked.connect(func(): 
		self.item_double_clicked.emit(data)
		texture_rect.set_selected.call_deferred(false)
	)
	
	# 拖拽
	texture_rect.dragged.connect(func(callback_data_list: Array):
		var selected_data_list = _data_list.filter(func(d): return d['selected'])
		if selected_data_list.is_empty():
			selected_data_list.append(data)
		callback_data_list.append_array(selected_data_list)
	)
	
	texture_rect.tree_exited.connect(func(): _data_list.erase(data) )


## 取消所有选中
func cancel_all_selected():
	for selecte_node in get_selected_node_list():
		selecte_node.set_selected(false)



#============================================================
#  连接信号
#============================================================
func _on_popup_menu_index_pressed(index):
	var id = item_popup_menu.get_item_id(index)
	match id:
		ImagePopupItem.PREVIEW:
			var texture = _last_right_clicked_item_data['texture']
			self.previewed.emit(texture)
		
		ImagePopupItem.REMOVE:
			var data_list = get_selected_data_list()
			for node in data_list.map(func(data): return data['node']):
				node.queue_free()
			
			await Engine.get_main_loop().process_frame
			await Engine.get_main_loop().process_frame
			prompt_label.visible = item_container.get_child_count() == 0
		
		ImagePopupItem.EXPORT_SELECTED_IMAGE:
			export_selected_dialog.popup_centered()


func _on_panel_popup_menu_index_pressed(index):
	var menu_name = panel_popup_menu.get_item_text(index)
	match menu_name:
		"CREATE_EMPTY_IMAGE":
			add_data({"texture": null})


func _on_group_dialog_confirmed():
	# (暂未实现功能)
	var group_name : String = group_name_edit.text.strip_edges()
	if group_name != "":
		var node_list = get_selected_node_list()
		for node in node_list:
			node.add_texture_group("group_name")
			


func _on_save_selected_dir_selected(dir: String):
	# 导出选中的图像
	var file_path : String
	var idx : int = 0
	for texture in get_selected_texture_list():
		file_path = dir.path_join("image_%03d.png" % idx)	# 保存为 png 图像
		while FileAccess.file_exists(file_path):
			idx += 1
		texture.get_image().save_png(file_path)
		idx += 1
	
	self.exported_texture.emit(get_selected_texture_list())
	


