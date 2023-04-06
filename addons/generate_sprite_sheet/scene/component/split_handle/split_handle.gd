#============================================================
#    Split Handle
#============================================================
# - author: zhangxuetu
# - datetime: 2023-04-03 22:25:31
# - version: 4.0
#============================================================
@tool
extends MarginContainer


## 更新切分的表格
signal split_grid_changed(margin: Vector2i, separator: Vector2i)
signal split_size(cell_size : Vector2i)
signal split_column_row(column_row: Vector2i)


#============================================================
#  内置
#============================================================
func _ready():
	GenerateSpriteSheetUtil.set_width_by_max_width([
		%margin_label, %separate_label, %split_size_btn, %split_column_row_btn
	])



#============================================================
#  连接信号
#============================================================
func _on_split_size_pressed():
	self.split_size.emit(Vector2i( %split_size.get_value() ))


func _on_split_column_row_pressed():
	self.split_column_row.emit(Vector2i(%split_column_row.get_value()))


func _on_item_vector_2_value_changed(value: Vector2):
	self.split_grid_changed.emit( %margin.get_value(), %separator.get_value() )


func _on_margin_value_changed(value):
	self.split_grid_changed.emit( %margin.get_value(), %separator.get_value() )
