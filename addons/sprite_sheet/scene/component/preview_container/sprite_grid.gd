#============================================================
#    Grid Rect
#============================================================
# - author: zhangxuetu
# - datetime: 2023-03-19 22:22:21
# - version: 4.0
#============================================================
## 选中位置的网格。
##
##[b]Node[/b]: 这个脚本可重复利用到其他项目中
@tool
class_name SpriteSheet_GridRect
extends Control


## [code]pos[/code] 为鼠标的位置，[code]coordinate[/code] 为点击的单元格的位置
signal selected(pos: Vector2i, coordinate: Vector2i, pressed: bool)
## 双击一片区域
signal double_clicked(pos: Vector2i, coordinate: Vector2i)


## 显示的网格的颜色
@export
var color : Color = Color.WHITE:
	set(v):
		color = v
		queue_redraw()
## 显示的网格的行列个数
@export
var column_row_number : Vector2i = Vector2i( 3, 3 ):
	set(v):
		v.x = max(1, v.x)
		v.y = max(1, v.y)
		column_row_number = v
		queue_redraw()
## 网格线宽度
@export_range(0, 100, 0.1, "or_greater")
var width : float =  1:
	set(v):
		width = v
		queue_redraw()
## 选中的单元格颜色
@export var select_color : Color = Color.ROYAL_BLUE
## 选中的单元格线段宽度
@export var select_width : int = 2
## 间隔距离
@export var separator : Vector2i = Vector2i():
	set(v):
		separator = v
		_draw_coordinate_list.clear()
		queue_redraw()
## 间隔距离颜色
@export_color_no_alpha var separator_color : Color = Color.WHITE_SMOKE:
	set(v):
		separator_color = v
		queue_redraw()
## 边距
@export var margin : Vector2i:
	set(v):
		margin = v
		_draw_coordinate_list.clear()
		queue_redraw()


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
	return get_cell_size_full() - separator

## 获取每个单元格整的占用的大小
func get_cell_size_full() -> Vector2i:
#	var margin_size = Vector2( margin.position.x + margin.size.x, margin.position.y + margin.size.y )
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

## 位置转为单元格坐标位置
func to_coodinate(pos: Vector2) -> Vector2i:
	var cell_size_full : Vector2i = get_cell_size_full()
	return (Vector2i(pos) - margin) / cell_size_full

## 单元格坐标转为具体位置
func to_position(coordinate: Vector2i) -> Vector2i:
	var cell_size_full = get_cell_size_full()
	return cell_size_full * coordinate + margin

## 获取这个坐标的块区域
func get_cell_rect_by_coord(coordinate: Vector2i) -> Rect2i:
	var pos = to_position(coordinate)
	var cell_size = get_cell_size()
	return Rect2i(pos, cell_size)

## 获取这个位置的表格区域
func get_cell_rect_by_position(pos: Vector2) -> Rect2i:
	return get_cell_rect_by_coord(to_coodinate(pos))



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
	var cell_size_full : Vector2i = get_cell_size_full()
	# 所有网格
	for column in column_row_number.x:
		for row in column_row_number.y:
			draw_rect(Rect2i(Vector2i(column, row) * cell_size_full + margin, cell_size), color, false, width)
	
	# 间隔
	if separator.x > 0 and separator.y > 0:
		var end_y : int = column_row_number.y * cell_size_full.y - separator.y + margin.y
		var end_x : int = column_row_number.x * cell_size_full.x - separator.x + margin.x
		
		var start_x : int
		for column in range(1, column_row_number.x):
			start_x = column * cell_size_full.x - separator.x / 2 + margin.x
			draw_line(Vector2i(start_x, margin.y), Vector2i(start_x, end_y), separator_color, separator.x)
		
		var start_y : int
		for row in range(1, column_row_number.y):
			start_y = row * cell_size_full.y - separator.y / 2 + margin.y
			draw_line(Vector2i(margin.x, start_y), Vector2i(end_x, start_y), separator_color, separator.y)
	
	# 选中的坐标
	for coordinate in _draw_coordinate_list:
		draw_rect(Rect2i(coordinate * cell_size_full + margin, cell_size), select_color, false, select_width)


func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# 点击
			if event.double_click:
				var pos : Vector2i = Vector2i(event.position)
				var coordinate : Vector2i = to_coodinate(event.position)
				self.double_clicked.emit(pos, coordinate)
				if _draw_coordinate_list.has(coordinate):
					_draw_coordinate_list.erase(coordinate)
				queue_redraw()
				
			else:
				if event.pressed:
					_update_select_status(event.position)
				else:
					_last_clicked_selected_coord.clear()
			
			_mouse_clicked_status = event.pressed
		
	elif event is InputEventMouseMotion:
		if _mouse_clicked_status:
			_update_select_status(event.position)



#============================================================
#  自定义
#============================================================
# 更新选中的区域的绘制状态
func _update_select_status(mouse_pos: Vector2):
	var pos : Vector2i = Vector2i(mouse_pos)
	if not get_rect().has_point(pos):
		return
	
	var cell_size : Vector2i = get_cell_size()
	var coordinate : Vector2i = to_coodinate(mouse_pos)
	# 还在同一个表格上则不会处理
	if _last_clicked_selected_coord.has(coordinate):
		return
	
	_last_clicked_selected_coord.append(coordinate)
	
	var pressed = false
	var last_selected_state = true
	if _last_clicked_selected_coord.size() > 0:
		# （连选）根据上次选中的状态来更新后续的节点
		var last_coordinate = _last_clicked_selected_coord.back()
		last_selected_state = not _draw_coordinate_list.has(last_coordinate)
		if last_selected_state:
			if not _draw_coordinate_list.has(coordinate):
				_draw_coordinate_list.append(coordinate)
		else:
			_draw_coordinate_list.erase(coordinate)
		
	else:
		
		if _draw_coordinate_list.has(coordinate):
			_draw_coordinate_list.erase(coordinate)
			pressed = false
		else:
			_draw_coordinate_list.push_back(coordinate)
			pressed = true
	
	self.selected.emit(pos, coordinate, pressed)
	queue_redraw()


##  根据单个单元格更新行列数量
##[br]
##[br][code]total_size[/code]  总大小
##[br][code]cell_size[/code]  每个单元格大小
func update_column_row_by_cell_size(total_size: Vector2i, cell_size: Vector2i):
	cell_size += separator
	var cell_grid = total_size / cell_size # 表格数量
	column_row_number = cell_grid
	self.size = cell_grid * cell_size


## 清空选中
func clear():
	_draw_coordinate_list.clear()
	queue_redraw()


## 选中一个坐标位置
func select(coordinate: Vector2i, cell_size: Vector2i = Vector2i()):
	if cell_size == Vector2i():
		cell_size = column_row_number
	if not _draw_coordinate_list.has(coordinate):
		_draw_coordinate_list.push_back(coordinate)
		
		var pos : Vector2i = coordinate * cell_size
		self.selected.emit(pos, coordinate, true)
		queue_redraw()

