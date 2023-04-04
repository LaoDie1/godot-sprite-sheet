#============================================================
#    Preview Handle
#============================================================
# - author: zhangxuetu
# - datetime: 2023-04-03 13:54:37
# - version: 4.0
#============================================================
@tool
extends MarginContainer


signal resize(new_size: Vector2i)
signal rescale(new_scale: Vector2)
signal recolor(from: Color, to: Color, threshold: float)
## 描边
signal outline(color: Color)
## 清空透明边界
signal clear_transparency


@onready var texture_width = %texture_width
@onready var texture_height = %texture_height
@onready var texture_scale_x = %texture_scale_x
@onready var texture_scale_y = %texture_scale_y
@onready var from_color = %from_color
@onready var to_color = %to_color
@onready var color_threshold = %color_threshold
@onready var outline_color = %outline_color


func _on_resize_pressed():
	self.resize.emit(Vector2i(texture_width.value, texture_height.value))


func _on_rescale_pressed():
	self.rescale.emit(Vector2( texture_scale_x.value, texture_scale_y.value ))


func _on_recolor_pressed():
	self.recolor.emit(from_color.color, to_color.color, color_threshold.value)


func _on_color_swap_pressed():
	var tmp = from_color.color
	from_color.color = to_color.color
	to_color.color = tmp


func _on_outline_pressed():
	self.outline.emit(outline_color.color)


func _on_clear_transparency_pressed():
	self.clear_transparency.emit()
	
