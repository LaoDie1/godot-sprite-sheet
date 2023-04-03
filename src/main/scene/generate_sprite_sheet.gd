#============================================================
#    Generate Sprite Sheet
#============================================================
# - author: zhangxuetu
# - datetime: 2023-03-31 00:21:22
# - version: 4.0
#============================================================
## 合并图片为一个精灵表
class_name GenerateSpriteSheetMain
extends MarginContainer


var TEXTURE_FILTER = func(file: String):
	return file.get_extension() in ["png", "jpg", "svg"]


# 菜单列表
@onready var menu_list := %menu_list as MenuList
# 文件树
@onready var file_tree := %file_tree as GenerateSpriteShee_FileTree
# 等待处理文件列表，拖拽进去，选中这个文件，可以从操作台中进行开始处理这个图片
# 处理后的文件在这里面保存，然后生成会从这个列表里生成处理
@onready var pending := %pending as GenerateSpriteSheet_Pending
# 预览图片
@onready var preview_container := %preview_container as GenerateSpriteSheet_PreviewContainer
# 操作处理容器
@onready var handle_container = %handle_container

@onready var export_panding_dialog := %export_panding_dialog as FileDialog
@onready var scan_dir_dialog := %scan_dir_dialog as FileDialog
@onready var export_preview_dialog = %export_preview_dialog

@onready var split_width = %split_width
@onready var split_height = %split_height
@onready var split_row = %split_row
@onready var split_column = %split_column
@onready var prompt_info_label = %prompt_info_label


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
	
	# 提示信息
	Engine.set_meta("GenerateSpriteSheetMain_node", self)
	prompt_info_label.modulate.a = 0


#============================================================
#  自定义
#============================================================
## 显示消息内容
static func show_message(message: String):
	if Engine.has_meta("GenerateSpriteSheetMain_node"):
		var node = Engine.get_meta("GenerateSpriteSheetMain_node") as GenerateSpriteSheetMain
		var label := node.prompt_info_label as Label
		label.text = message
		
		# 播放动画效果
		var tween : Tween 
		var key = "tween"
		if label.has_meta(key):
			tween = label.get_meta(key) as Tween
			if is_instance_valid(tween):
				tween.stop()
		tween = label.create_tween()
		label.set_meta(key, tween)
		
		tween.tween_property(label, "modulate:a", 1, 0.2) \
			.set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(label, "modulate:a", 0, 0.5) \
			.set_ease(Tween.EASE_IN_OUT) \
			.set_delay(3)


class IfTrue:
	var _value
	
	func _init(value):
		_value = value
	
	func else_show_message(message: String):
		if _value:
			pass
		else:
			GenerateSpriteSheetMain.show_message(message)
	
	##  如果值为 [code]true[/code] 则执行回调方法
	##[br]
	##[br][code]callback[/code] 这个方法需要有一个参数用于接收上个回调的值 
	func if_true(callback: Callable) -> IfTrue:
		if _value:
			return IfTrue.new(callback.call(_value))
		return IfTrue.new(null)


##  如果值为 [code]true[/code] 则执行回调方法
##[br]
##[br][code]callback[/code]  这个方法没有任何参数，可以有一个返回值用于下一个 if_true 方法的执行，如果没有返回值，
##则默认为 value 参数值
##[br][code]return[/code]  返回一个 IfTrue 对象用以链式调用执行功能
static func if_true(value, callback: Callable) -> IfTrue:
	if value:
		var r = callback.call()
		return IfTrue.new(r if r else value)
	return IfTrue.new(null)


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
		pending.add_data({ texture = image_texture })
	preview_container.clear_select()


func _on_clear_select_pressed():
	preview_container.clear_select()


func _on_select_all_pressed():
	if preview_container.has_texture():
		if_true(preview_container.get_preview_grid_visible(), func():
			var grid = preview_container.get_cell_grid()
			for x in grid.x:
				for y in grid.y:
					var coordinate = Vector2i(x, y)
					preview_container.select(coordinate)
		).else_show_message("还未进行切分！")


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


func _on_split_column_row_pressed():
	if_true(preview_container.has_texture(), func():
		var column_row = Vector2i( split_column.value, split_row.value )
		var texture_size = Vector2i(preview_container.get_texture().get_size())
		var cell_size = texture_size / column_row
		preview_container.split(cell_size)
	).else_show_message("没有预览图片")


func _on_split_size_pressed():
	if_true(preview_container.has_texture(), func():
		preview_container.split(Vector2i( split_width.value, split_height.value ))
	).else_show_message("没有预览图片")


func _on_export_panding_dialog_dir_selected(dir: String):
	if_true(DirAccess.dir_exists_absolute(dir), func():
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
		print("已导出文件：")
		print(exported_file_list)
	).else_show_message("没有这个目录")


func _on_animation_panel_played(animation: Animation):
	preview_container.play(animation)


func _on_animation_panel_stopped():
	preview_container.stop()


func _on__merged(data: GenerateSpriteSheet_PendingHandle.Merge):
	var texture_list : Array[Texture2D] = pending.get_selected_texture_list()
	if_true(texture_list, func():
		var max_column : int = data.max_column
		var max_row : int = ceil(texture_list.size() / float(data.max_column))
		
		# 每个图块大小
		var sub_image_size : Vector2i = Vector2i(0, 0)
		if data.merge_type == GenerateSpriteSheet_PendingHandle.MergeMode.MAX_SIZE:
			# 找到最大宽和高
			var idx : int = 0
			var texture : Texture2D
			for y in max_row:
				for x in max_column:
					if idx < texture_list.size():
						texture = texture_list[idx]
						idx += 1
						if sub_image_size.x < texture.get_size().x:
							sub_image_size.x = texture.get_size().x
						if sub_image_size.y < texture.get_size().y:
							sub_image_size.y = texture.get_size().y
						
					else:
						break
				if idx < texture_list.size():
					break
		else:
			# 设置的宽高参数
			sub_image_size = Vector2i(data.width, data.height)
		
		print(sub_image_size)
		
		# 每个图块包含边距的大小
		var cell_size =  Vector2i(
			(sub_image_size.x + data.left_separation + data.right_separation), 
			(sub_image_size.y + data.top_separation + data.down_separation)
		)
		
		# 整张图片大小
		var image_width : int = ( data.left_margin + data.right_margin + cell_size.x * data.max_column )
		var image_height : int  = ( data.top_margin + data.down_margin + cell_size.y * max_row )
		var image_format = texture_list[0].get_image().get_format()
		var merge_image : Image = Image.create(image_width, image_height, false, image_format)
		
		# 开始合并
		var coordinate : Vector2i
		var x : int
		var y : int 
		var idx = 0
		var image : Image
		
		for texture in texture_list:
			x = idx % max_column
			y = idx / max_column
			coordinate = Vector2i(x, y) * cell_size
			image = texture.get_image()
			if data.merge_type == GenerateSpriteSheet_PendingHandle.MergeMode.SCALE:
				# 缩放到指定大小
				image = GenerateSpriteSheetUtil.resize_image(image, sub_image_size)
			merge_image.blit_rect(image, Rect2i(Vector2i(), cell_size), coordinate)
			idx += 1
		
		# 预览
		var merge_texture = ImageTexture.create_from_image(merge_image)
		preview_container.preview(merge_texture)
		
	).else_show_message("没有选中任何图像")


func _on_export_preview_pressed():
	if_true(preview_container.get_texture(), func():
		export_preview_dialog.popup_centered()
	).else_show_message("没有预览图像")


func _on_export_preview_dialog_file_selected(path):
	# 导出预览图像
	if preview_container.get_texture():
		var texture = preview_container.get_texture()
		ResourceSaver.save(texture, path)
		show_message("已保存预览图像")


func _on__resize_selected(new_size: Vector2i):
	var data_list = pending.get_selected_data_list()
	if_true(data_list, func():
		# 重置待处理区图片大小
		for data in pending.get_selected_data_list():
			var texture = data['texture'] as Texture2D
			if Vector2i(texture.get_size()) != new_size:
				var node = data['node'] as Control
				data['texture'] = GenerateSpriteSheetUtil.resize_texture(texture, new_size)
				node.set_data(data)
	).else_show_message("没有选中的图像")


func _on__rescale(texture_scale: Vector2i):
	if_true(preview_container.has_texture(), func():
		# 缩放
		var texture = preview_container.get_texture()
		var new_texture = GenerateSpriteSheetUtil.scale_texture(texture, texture_scale)
	#	pending.add_data({ "texture": new_texture })
		preview_container.preview(new_texture)
	).else_show_message("没有预览图片")


func _on__resize(texture_size):
	if_true(preview_container.has_texture(), func():
		# 重设大小
		var texture = preview_container.get_texture()
		var new_texture = GenerateSpriteSheetUtil.resize_texture(texture, texture_size)
	#	pending.add_data({"texture": new_texture })
		preview_container.preview(new_texture)
	).else_show_message("没有预览图片")


func _on__recolor(from: Color, to: Color, threshold: float):
	if_true(preview_container.has_texture(), func():
		var texture = preview_container.get_texture()
		var new_texture = GenerateSpriteSheetUtil.replace_color(texture, from, to, threshold)
		preview_container.preview(new_texture, false)
	).else_show_message("没有预览图片")
