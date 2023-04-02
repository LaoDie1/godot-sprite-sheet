#============================================================
#    Pending Handle
#============================================================
# - author: zhangxuetu
# - datetime: 2023-04-02 18:11:15
# - version: 4.0
#============================================================
## 待处理操作
class_name GenerateSpriteSheet_PendingHandle
extends MarginContainer


signal merged(data: Merge)


@onready var max_column = %max_column
@onready var width = %width
@onready var height = %height
@onready var left_separation = %left_separation
@onready var right_separation = %right_separation
@onready var top_separation = %top_separation
@onready var down_separation = %down_separation
@onready var left_margin = %left_margin
@onready var right_margin = %right_margin
@onready var top_margin = %top_margin
@onready var down_margin = %down_margin
@onready var scale_image = %scale_image


class Merge:
	var max_column : int
	var width : int
	var height: int
	var left_separation : int
	var right_separation : int
	var top_separation : int
	var down_separation : int
	var left_margin : int
	var right_margin : int
	var top_margin : int 
	var down_margin : int 
	var scale : bool
	
	func _init(data: Dictionary):
		for prop in data:
			set(prop, data[prop])
	



#============================================================
#  连接信号
#============================================================
func _on_merge_pressed():
	merged.emit(Merge.new({
		"max_column": max_column.value,
		"width": width.value,
		"height": height.value,
		"left_separation": left_separation.value,
		"right_separation": right_separation.value,
		"top_separation": top_separation.value,
		"down_separation": down_separation.value,
		"left_margin": left_margin.value,
		"right_margin": right_margin.value,
		"top_margin": top_margin.value,
		"down_margin": down_margin.value,
		"scale": scale_image.button_pressed,
	}))
