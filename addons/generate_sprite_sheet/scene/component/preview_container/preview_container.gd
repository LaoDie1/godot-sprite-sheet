#============================================================
#    Preview Container
#============================================================
# - author: zhangxuetu
# - datetime: 2023-03-31 13:50:35
# - version: 4.0
#============================================================
## 预览图像容器
@tool
class_name GenerateSpriteSheet_PreviewContainer
extends MarginContainer


## 双击创建这个区域的图片
signal created_texture(texture: Texture2D)


## 默认左上角位置
const DEFAULT_LEFT_TOP_POS = Vector2(8, 32)


# 预览的画布
@onready var preview_canvas := %preview_canvas as Control
# 预览
@onready var preview_rect := %preview_rect as TextureRect
# 预览值标签
@onready var preview_scale_label := %preview_scale_label as Label
# 切分的表格
@onready var preview_split_grid := %preview_split_grid as GenerateSpriteSheet_GridRect
# 边界边框
@onready var border_rect = %border_rect
@onready var border_rect_margin = %border_rect_margin
# 手动选中区域框
@onready var manual_rect = %manual_rect
# 用于播放动画
@onready var preview_anim_player = %preview_anim_player as AnimationPlayer

@onready var texture_size_label = %texture_size_label


# 运行预览缩放（防止鼠标滚轮滚动过快）
var _enabled_preview_scale : bool = true
# 当前图片缩放
var _preview_scale : float = 0
# 正在按下左键
var _left_mouse_pressed : bool = false
var _left_mouse_pressed_pos : Vector2i = Vector2i(0, 0)
# 鼠标中键拖拽画布
var _middle_drag_canvas_mouse_pos : Vector2 = Vector2(0,0)
var _middle_drag_canvas_rect_pos : Vector2 = Vector2(0,0)
var _middle_drag : bool = false


#============================================================
#  SetGet
#============================================================
## 是否有预览的图像
func has_texture() -> bool:
	return preview_rect.texture != null


func get_texture() -> Texture2D:
	return preview_rect.texture


func get_selected_texture_list() -> Array[ImageTexture]:
	var texture : Texture2D = preview_rect.texture
	var list : Array[ImageTexture] = []
	var rect : Rect2i
	var new_texture : ImageTexture
	# 选中的表格中创建图片
	for coordinate in preview_split_grid.get_selected_coordinate_list():
		# 创建这个区域的图片
		rect = preview_split_grid.get_cell_rect_by_coord(coordinate)
		new_texture = GenerateSpriteSheetUtil.create_texture_by_rect(texture, rect)
		list.append(new_texture)
	
	return list


## 获取单元格表格数
func get_cell_grid() -> Vector2i:
	if preview_split_grid.visible:
		return preview_split_grid.column_row_number # 表格
	return Vector2i(0, 0)


## 获取选择表格可见性
func get_preview_grid_visible() -> bool:
	return preview_split_grid.visible


#============================================================
#  内置
#============================================================
func _ready():
	preview_rect.item_rect_changed.connect(func():
		preview_canvas.custom_minimum_size = preview_rect.size * preview_rect.scale
	)
	clear_texture()
	move_preview_texture(DEFAULT_LEFT_TOP_POS)


#============================================================
#  自定义
#============================================================
# 更新预览缩放 
func _update_preview_scale(add_v: float = 0.0):
	if _enabled_preview_scale:
		_preview_scale += add_v
		_preview_scale = clamp(_preview_scale, -5, 10)
		# 更新图像缩放
		var v = pow(2, _preview_scale)
		preview_rect.scale = Vector2(v, v) 
		preview_scale_label.text = str(int(v * 100)) + "%"
		preview_canvas.custom_minimum_size = preview_rect.size * preview_rect.scale
		
		# 表格线保持宽度，防止缩放太小看不见
		preview_split_grid.width = max(0.5, 1.0 / v)
		preview_split_grid.select_width = ceil(2.0 / v)
		border_rect.border_width = 2.0 / v
		
		# 等待一点时间，防止过快的缩放
		_enabled_preview_scale = false
		await get_tree().create_timer(0.05).timeout
		_enabled_preview_scale = true


## 清除显示的图像
func clear_texture():
	if has_texture():
		preview_anim_player.stop()
		preview_rect.texture = null
		preview_split_grid.visible = false
	#	preview_rect.position = DEFAULT_LEFT_TOP_POS
		preview_rect.size = Vector2()
		texture_size_label.visible = false
	clear_select()


## 清除选中的表格内容
func clear_select():
	preview_split_grid.clear()


func hide_select_grid():
	preview_split_grid.visible = false


##  预览图片  
func preview(texture: Texture2D, reset_pos: bool = false):
	# 显示图片
	preview_rect.texture = texture
	if reset_pos:
		move_preview_texture(DEFAULT_LEFT_TOP_POS)
	preview_split_grid.visible = false
	texture_size_label.visible = true
	texture_size_label.text = "Size: (%s, %s)" % [texture.get_width(), texture.get_height()]
	preview_rect.size = texture.get_size()
	border_rect_margin.size = texture.get_size()
	border_rect_margin.position = Vector2(0, 0)
	_update_preview_scale()
	if preview_anim_player.is_playing():
		preview_anim_player.stop()


##  切分图像，显示表格
##[br]
##[br][code]split_size[/code]  切分的每个单元格大小
func split(split_size: Vector2):
	if preview_rect.texture != null:
		var preview_texture : Texture2D = preview_rect.texture
		
		# 预览表格
		preview_split_grid.update_column_row_by_cell_size(preview_texture.get_size(), split_size)
		preview_split_grid.visible = true
		
		border_rect.visible = true
		clear_select()


## 选中一个坐标的单元格区域的图像
func select(coordinate: Vector2i, cell_size: Vector2i = Vector2i()):
	if has_texture():
		preview_split_grid.select(coordinate, cell_size)
	preview_split_grid.visible = true
	border_rect.visible = true


## 移动显示图片的位置
func move_preview_texture(pos: Vector2):
	preview_rect.position = pos


## 播放动画
func play(animation: Animation):
	clear_select()
	
	# 预览第一张图片，更新预览相关的数据
	var texture = animation.track_get_key_value(0, 0) as Texture2D
	preview(texture, false)
	
	if (preview_rect.position.x < 0 or preview_rect.position.y < 0
		or preview_rect.position.x >= self.size.x or preview_rect.position.y >= self.size.y
	):
#		move_preview_texture(Vector2i(self.size / 2))
		move_preview_texture(DEFAULT_LEFT_TOP_POS)
	
#	border_rect.visible = false
	preview_split_grid.visible = false
	
	# 播放动画
	preview_anim_player.stop()
	var ANIM_NAME = "anima"
	var lib = preview_anim_player.get_animation_library("")
	if lib.has_animation(ANIM_NAME):
		lib.remove_animation(ANIM_NAME)
	lib.add_animation(ANIM_NAME, animation)
	preview_anim_player.play(ANIM_NAME)


## 停止播放动画
func stop():
	preview_anim_player.stop()


## 更新切分网格间隔距离
func update_grid_separator(value: Vector2i):
	preview_split_grid.separator = value


## 更新切分网格边距
func update_grid_margin(value: Vector2i):
	preview_split_grid.margin = value


#============================================================
#  连接信号
#============================================================
func _on_preview_canvas_gui_input(event):
	if event is InputEventMouseButton:
		# 缩放图片
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_update_preview_scale(-0.5)
			get_tree().root.set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_update_preview_scale(0.5)
			get_tree().root.set_input_as_handled()
		
		# 按下中间开始拖拽 
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			_middle_drag_canvas_mouse_pos = get_global_mouse_position()
			_middle_drag_canvas_rect_pos = preview_rect.position
			_middle_drag = event.pressed
		
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_left_mouse_pressed = not preview_split_grid.visible
				_left_mouse_pressed_pos = Vector2i( get_global_mouse_position() )
			else:
				_left_mouse_pressed = false
			
		
	elif event is InputEventMouseMotion:
		# 中键拖拽画布，移动图片
		if _middle_drag:
			var diff = get_global_mouse_position() - _middle_drag_canvas_mouse_pos
			preview_rect.position = clamp(_middle_drag_canvas_rect_pos + diff, -preview_rect.size, self.size)
		
		elif _left_mouse_pressed_pos:
			_left_mouse_pressed_pos
			


func _on_preview_grid_double_clicked(pos: Vector2i, coordinate: Vector2i):
	# 双击创建对应区域的图片
	if preview_rect.texture:
		var rect = preview_split_grid.get_cell_rect_by_position(pos)
		if rect.size == Vector2i.ZERO:
			print("[ GenerateSpriteSheet ] 没有表格大小")
			return
		
		# 创建这个区域的图片
		var texture : Texture2D = preview_rect.texture
		var new_texture = GenerateSpriteSheetUtil.create_texture_by_rect(texture, rect)
		self.created_texture.emit(new_texture)
	

