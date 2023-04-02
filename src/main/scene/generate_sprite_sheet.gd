#============================================================
#    Generate Sprite Sheet
#============================================================
# - author: zhangxuetu
# - datetime: 2023-03-31 00:21:22
# - version: 4.0
#============================================================
## 合并图片为一个精灵表
## 
extends MarginContainer


var TEXTURE_FILTER = func(file: String):
	return file.get_extension() in ["png", "jpg", "svg"]


# 菜单列表
@onready var menu_list := %menu_list as MenuList
# 文件树
@onready var file_tree := %file_tree as GenerateSpriteShee_FileTree
# 等待处理文件列表，拖拽进去，选中这个文件，可以从操作台中进行开始处理这个图片
# 处理后的文件在这里面保存，然后生成会从这个列表里生成处理
@onready var pending := %pending as GenerateSpriteShee_Panding
# 预览图片
@onready var preview_container := %preview_container as GenerateSpriteSheet_PreviewContainer
# 操作处理容器
@onready var handle_container = %handle_container

@onready var export_panding_dialog := %export_panding_dialog as FileDialog
@onready var scan_dir_dialog := %scan_dir_dialog as FileDialog
@onready var export_preview_dialog = %export_preview_dialog

@onready var split_width = %split_width
@onready var split_height = %split_height
@onready var texture_width = %texture_width
@onready var texture_height = %texture_height
@onready var texture_scale_x = %texture_scale_x
@onready var texture_scale_y = %texture_scale_y
@onready var split_row = %split_row
@onready var split_column = %split_column


#============================================================
#  内置
#============================================================
func _ready():
	# 初始化菜单
	menu_list.init_menu({
		"文件": ["扫描目录"],
		"导出": ["导出所有待处理图像"]
	})
	
	# 扫描加载文件列表
	var path = "res://src/main/assets/texture/"
	file_tree.update_tree(path, TEXTURE_FILTER)
	
	# 边距
	for child in handle_container.get_children():
		if child is MarginContainer:
			for dir in ["left", "right", "top", "bottom"]:
				child.set("theme_override_constants/margin_" + dir, 8)
	



#============================================================
#  连接信号
#============================================================
func _on_file_tree_selected(path_type, path):
	preview_container.clear_texture()
	if path_type == GenerateSpriteShee_FileTree.PathType.FILE:
		var res = load(path)
		if res is Texture2D:
			preview_container.preview(res)


func _on_file_tree_added_item(item: TreeItem):
	# 文件树添加新的 item 时
	var data = item.get_metadata(0) as Dictionary
	if data.path_type == GenerateSpriteShee_FileTree.PathType.FILE:
		var path = data.path
		var texture = load(path)
		item.set_icon(0, texture)
		item.set_icon_max_width(0, 16)


func _on_preview_container_created_texture(texture: Texture2D):
	pending.add_data({
		"texture": texture,
		"path": "",
	})


func _on_add_selected_rect_pressed():
	# 添加选中的表格区域的图片到待处理区
	for image_texture in preview_container.get_selected_texture_list():
		pending.add_data({
			"texture": image_texture
		})
	preview_container.clear_select()


func _on_clear_select_pressed():
	preview_container.clear_select()


func _on_select_all_pressed():
	if preview_container.has_texture():
		if not preview_container.get_preview_grid_visible():
			printerr("[ GenerateSpriteSheet ] 还未进行切分！")
			
		
		var grid = preview_container.get_cell_grid()
		for x in grid.x:
			for y in grid.y:
				var coordinate = Vector2i(x, y)
				preview_container.select(coordinate)


func _on_menu_list_menu_pressed(idx, menu_path):
	match menu_path:
		"/文件/扫描目录":
			scan_dir_dialog.popup_centered()
		
		"/导出/导出所有待处理图像":
			export_panding_dialog.popup_centered()


func _on_file_dialog_dir_selected(dir):
	file_tree.update_tree(dir, TEXTURE_FILTER)


func _on_pending_item_double_clicked(data):
	# 预览双击的图片
	var texture = data["texture"]
	preview_container.preview(texture)


func _on_resize_pressed():
	# 重设大小
	var texture_size = Vector2i(texture_width.value, texture_height.value)
	var texture = preview_container.get_texture()
	var new_texture = GenerateSpriteSheetUtil.resize_texture(texture, texture_size)
	pending.add_data({
		"texture": new_texture
	})


func _on_scale_pressed():
	# 缩放
	var texture_scale = Vector2(texture_scale_x.value, texture_scale_y.value)
	var texture = preview_container.get_texture()
	var new_texture = GenerateSpriteSheetUtil.scale_texture(texture, texture_scale)
	pending.add_data({
		"texture": new_texture
	})


func _on_split_column_row_pressed():
	var column_row = Vector2i( split_column.value, split_row.value )
	var texture_size = Vector2i(preview_container.get_texture().get_size())
	var cell_size = texture_size / column_row
	preview_container.split(cell_size)


func _on_split_size_pressed():
	preview_container.split(Vector2i( split_width.value, split_height.value ))


func _on_export_panding_dialog_dir_selected(dir: String):
	if DirAccess.dir_exists_absolute(dir):
		var list = pending.get_texture_list()
		var idx = -1
		var exported_file_list : Array[String] = []
		var filename : String 
		for texture in list:
			while true:
				idx += 1
				filename = "subtexture_%04d.png" % idx
				if not FileAccess.file_exists(filename):
					break
			exported_file_list.append(dir.path_join(filename))
			ResourceSaver.save(texture, exported_file_list.back() )
		print("[ GenerateSpriteSheet ] 已导出文件：")
		print(exported_file_list)
	
	else:
		printerr("[ GenerateSpriteSheet ] 没有这个目录")
	


func _on_animation_panel_played(animation: Animation):
	preview_container.play(animation)


func _on_animation_panel_stopped():
	preview_container.stop()


func _on__merged(data: GenerateSpriteSheet_PendingHandle.Merge):
	var texture_list : Array[Texture2D] = pending.get_selected_texture_list()
	
	if texture_list.is_empty():
		printerr("[ GenerateSpriteSheet ] 没有选中任何图像")
		return
	
	# 每个图块区域宽高
	var max_row : int = ceil(texture_list.size() / float(data.max_column))
	var cell_size =  Vector2i(
		(data.width + data.left_separation + data.right_separation), 
		(data.height + data.top_separation + data.down_separation)
	)
	# 生成的图像大小
	var image_width : int = ( data.left_margin + data.right_margin + cell_size.x * data.max_column )
	var image_height : int  = ( data.top_margin + data.down_margin + cell_size.y * max_row )
	var image_format = texture_list[0].get_image().get_format()
	var merge_image : Image = Image.create(image_width, image_height, false, image_format)
	
	# 合并
	var coordinate : Vector2i
	var x : int
	var y : int 
	var idx = 0
	var image : Image
	var sub_image_size : Vector2i = Vector2i(data.width, data.height)
	for texture in texture_list:
		x = idx % data.max_column
		y = idx / data.max_column
		coordinate = Vector2i(x, y) * cell_size
		image = texture.get_image()
		if data.scale:
			image = GenerateSpriteSheetUtil.resize_image(image, sub_image_size)
		merge_image.blit_rect(image, Rect2i(Vector2i(), cell_size), coordinate)
		idx += 1
	
	# 预览
	var merge_texture = ImageTexture.create_from_image(merge_image)
	Log.info([sub_image_size, cell_size, Vector2i(image_width, image_height), merge_texture])
	preview_container.preview(merge_texture)


func _on_export_preview_pressed():
	if preview_container.get_texture() != null:
		printerr("[ GenerateSpriteSheet ] 没有预览图像")
		return
	export_preview_dialog.popup_centered()


func _on_export_preview_dialog_file_selected(path):
	# 导出预览图像
	if preview_container.get_texture() != null:
		var texture = preview_container.get_texture()
		ResourceSaver.save(texture, path)
		print("[ GenerateSpriteSheet ] 已保存预览图像")

