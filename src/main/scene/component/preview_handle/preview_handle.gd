#============================================================
#    Preview Handle
#============================================================
# - author: zhangxuetu
# - datetime: 2023-04-03 13:54:37
# - version: 4.0
#============================================================
extends MarginContainer


signal resize(new_size: Vector2i)
signal rescale(new_scale: Vector2)
signal recolor(from: Color, to: Color, threshold: float)


@onready var texture_width = %texture_width
@onready var texture_height = %texture_height
@onready var texture_scale_x = %texture_scale_x
@onready var texture_scale_y = %texture_scale_y
@onready var from_color = %from_color
@onready var to_color = %to_color
@onready var color_threshold = %color_threshold


func _on_resize_pressed():
	self.resize.emit(Vector2i(texture_width.value, texture_height.value))


func _on_rescale_pressed():
	self.rescale.emit(Vector2( texture_scale_x.value, texture_scale_y.value ))


func _on_recolor_pressed():
	self.recolor.emit(from_color.color, to_color.color, color_threshold.value)

