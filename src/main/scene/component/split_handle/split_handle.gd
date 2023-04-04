#============================================================
#    Split Handle
#============================================================
# - author: zhangxuetu
# - datetime: 2023-04-03 22:25:31
# - version: 4.0
#============================================================
extends MarginContainer


signal split_size(cell_size : Vector2i)
signal split_column_row(column_row: Vector2i)


@onready var split_width = %split_width
@onready var split_height = %split_height
@onready var split_column = %split_column
@onready var split_row = %split_row
@onready var separactor_width = %separactor_width
@onready var separactor_height = %separactor_height



func _on_split_size_pressed():
	self.split_size.emit(Vector2i( split_width.value, split_height.value ))


func _on_split_column_row_pressed():
	self.split_column_row.emit(Vector2i(split_column.value, split_row.value))
