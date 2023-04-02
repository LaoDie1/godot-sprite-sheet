#============================================================
#    Grid Rect
#============================================================
# - author: zhangxuetu
# - datetime: 2023-03-19 22:22:21
# - version: 4.0
#============================================================
class_name GenerateSpriteSheet_GridRect
extends Control


## [code]pos[/code] 为鼠标的位置，[code]coordinate[/code] 为点击的单元格的位置
signal selected(pos: Vector2i, coordinate: Vector2i, pressed: bool)
signal double_clicked(pos: Vector2i, coordinate: Vector2i)


@export
var color : Color = Color.WHITE:
	set(v):
		color = v
		queue_redraw()
@export
var column_row_number : Vector2i = Vector2i( 3, 3 ):
	set(v):
		column_row_number = v
		queue_redraw()
@export_range(0, 100, 0.1, "or_greater")
var width : float =  1:
	set(v):
		width = v
		queue_redraw()
@export
var select_color : Color = Color.ROYAL_BLUE
@export
var select_width : int = 2


# 绘制矩形的坐标列表
var _draw_coordinate_list : Array[Vector2i] = []

# 鼠标点击状态
var _mouse_clicked_status := false
var _last_clicked_selected_coord : Array[Vector2i] = []


#============================================================
#  SetGet
#============================================================
## 获取每个单元格大小
func get_cell_size() -> Vector2i:
	return Vector2i(size) / column_row_number


## 获取选中的表格单元格坐标列表
func get_selected_coordinate_list() -> Array[Vector2i]:
	_draw_coordinate_list.sort_custom(func(a: Vector2i, b: Vector2i):
		if a.y > b.y:
			return false
		elif a.y == b.y:
			return a.x < b.x
		return true
	)
	return _draw_coordinate_list


## 转为单元格坐标位置
func convert_coodinate(pos: Vector2):
	var cell_size : Vector2i = get_cell_size()
	return Vector2i((pos / Vector2(cell_size)))


#============================================================
#  内置
#============================================================
func _ready():
	queue_redraw()
	visibility_changed.connect(func():
		if not visible:
			_draw_coordinate_list.clear()
	)


func _draw():
	var cell_size : Vector2i = get_cell_size()
	for column in column_row_number.x:
		for row in column_row_number.y:
			draw_rect(Rect2i(Vector2i(column, row) * cell_size, cell_size), color, false, width)
	
	for coordinate in _draw_coordinate_list:
		draw_rect(Rect2i(coordinate * cell_size, cell_size), select_color, false, select_width)


func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# 点击
			if event.double_click:
				var cell_size : Vector2i = get_cell_size()
				var coordinate = Vector2i((event.position / Vector2(cell_size)))
				var pos : Vector2i = coordinate * cell_size
				self.double_clicked.emit(pos, coordinate)
				if _draw_coordinate_list.has(coordinate):
					_draw_coordinate_list.erase(coordinate)
				queue_redraw()
				
			else:
				if event.pressed:
					_last_clicked_selected_coord.clear()
					_update_select_status(event.position)
			
			_mouse_clicked_status = event.pressed
		
		
	elif event is InputEventMouseMotion:
		if _mouse_clicked_status:
			_update_select_status(event.position)



#============================================================
#  自定义
#============================================================
# 更新选中的区域的绘制状态
func _update_select_status(mouse_pos: Vector2):
	mouse_pos = mouse_pos.floor()
	if not get_rect().has_point(mouse_pos):
		return
	
	var cell_size : Vector2i = get_cell_size()
	var coordinate = convert_coodinate(mouse_pos)
	# 还在同一个表格上则不会处理
	if _last_clicked_selected_coord.has(coordinate):
		return
	
	_last_clicked_selected_coord.append(coordinate)
	
	var pos : Vector2i = coordinate * cell_size
	var pressed = false
	if _draw_coordinate_list.has(coordinate):
		_draw_coordinate_list.erase(coordinate)
		pressed = false
	else:
		_draw_coordinate_list.push_back(coordinate)
		pressed = true
	
	self.selected.emit(pos, coordinate, pressed)
	queue_redraw()


func clear():
	_draw_coordinate_list.clear()
	queue_redraw()


func select(coordinate: Vector2i, cell_size: Vector2i = Vector2i()):
	if cell_size == Vector2i():
		cell_size = column_row_number
	if not _draw_coordinate_list.has(coordinate):
		_draw_coordinate_list.push_back(coordinate)
		
		var pos : Vector2i = coordinate * cell_size
		self.selected.emit(pos, coordinate, true)
		queue_redraw()

