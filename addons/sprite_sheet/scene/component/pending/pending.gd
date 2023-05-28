#============================================================
#    Pending
#============================================================
# - author: zhangxuetu
# - datetime: 2023-03-31 08:38:06
# - version: 4.0
#============================================================
# 待处理图片管理
@tool
class_name SpriteSheet_Pending
extends PanelContainer


signal item_selected(data: Dictionary)
signal item_right_clicked(data: Dictionary)
signal item_double_clicked(data: Dictionary)
signal previewed(texture: Texture2D)
signal exported_texture(texture_list: Array[Texture2D])


const ITEM_SCENE = preload("../texture_node_item/item.tscn")


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


var _last_right_clicked_item_data : Dictionary

var texture_item_group := SpriteSheetTextureItemGroup.new()


#============================================================
#  SetGet
#============================================================
func get_config_data() -> Dictionary:
	return SpriteSheetUtil.get_config_data("SpriteSheet_Pending")

## 获取所有待处理数据
func get_data_list() -> Array[Dictionary]:
	return texture_item_group.get_data_list()


#============================================================
#  内置
#============================================================
func _ready():
	texture_item_group.selected.connect(func(item: SpriteSheetTextureItem):
		self.item_selected.emit(item.get_data())
	)
	texture_item_group.double_clicked.connect(func(item):
		self.item_double_clicked.emit(item.get_data())
	)
	texture_item_group.right_clicked.connect(func(item):
		
		item_popup_menu.popup(Rect2(get_global_mouse_position(), Vector2(0,0)))
		self.item_right_clicked.emit(item.get_data())
	)
	
	prompt_label.visible = true
	
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
	if not config.has(KEY):
		config[KEY] = texture_item_group.get_data_list()
	var data_list = config[KEY]
	for data in data_list:
		add_data(data)
	config[KEY] = texture_item_group.get_data_list()
	
	prompt_label.visible = texture_item_group.get_data_list().is_empty()


func _can_drop_data(at_position, data):
	return (data is Dictionary
		and data.has("type")
		and data['type'] in SpriteSheetUtil.DragType.values()
	)


func _drop_data(at_position, data):
	if data["type"] == SpriteSheetUtil.DragType.Files:
		for file_path in data["files"]:
			add_data({
				"texture": SpriteSheetUtil.load_image(file_path),
				"path": file_path
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
var _can_handle_selected : Array = [true]

## 添加数据。这个数据必须要有 texture key 的数据，且数据类型需要是 [Texture2D] 类型
func add_data(data: Dictionary):
	data = data.duplicate()
	
	assert(data.has("texture"), "必须要含有 texture key 的数据")
	var item_node := ITEM_SCENE.instantiate() as SpriteSheetTextureItem
	item_node.custom_minimum_size = Vector2(64, 64)
	item_container.add_child(item_node)
	prompt_label.visible = false
	data['selected'] = false
	
	var texture = data.get('texture') as Texture2D
	if texture == null or texture.get_image().is_empty():
		data['texture'] = ImageTexture.create_from_image(Image.create(1, 1, false, Image.FORMAT_BPTC_RGBA))
	
	item_node.set_data(data)
	texture_item_group.add_item(item_node)


## 取消所有选中
func cancel_all_selected():
	for selecte_node in texture_item_group.get_selected_node_list():
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
			var data_list = texture_item_group.get_selected_data_list()
			for node in data_list.map(func(data): return data['node']):
				node.remove()
			
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
		var node_list = texture_item_group.get_selected_node_list()
		for node in node_list:
			node.add_texture_group("group_name")
			


func _on_save_selected_dir_selected(dir: String):
	# 导出选中的图像
	var file_path : String
	var idx : int = 0
	for texture in texture_item_group.get_selected_texture_list():
		file_path = dir.path_join("image_%03d.png" % idx)	# 保存为 png 图像
		while FileAccess.file_exists(file_path):
			idx += 1
		texture.get_image().save_png(file_path)
		idx += 1
	
	self.exported_texture.emit(texture_item_group.get_selected_texture_list())
	


