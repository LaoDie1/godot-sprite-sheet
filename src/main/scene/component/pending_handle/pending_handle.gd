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
signal resize_selected(new_size: Vector2i)


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
@onready var merge_mode = %merge_mode
@onready var select_texture_width = %select_texture_width
@onready var select_texture_height = %select_texture_height


enum MergeMode {
	SCALE,		# 缩放图像到指定大小后合并
	CUT,		# 按照定宽度合并图片，剪切掉超出的部分
	MAX_SIZE,	# 按照最大宽高设置图片
}

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
	var merge_type : int
	
	func _init(data: Dictionary):
		for prop in data:
			set(prop, data[prop])
	


#============================================================
#  内置
#============================================================
func _ready():
	var mode_type : Dictionary = {
		MergeMode.SCALE: "缩放到指定大小",
		MergeMode.CUT: "剪切掉多余部分",
		MergeMode.MAX_SIZE: "按最大图像大小设置每个图块",
	}
	for i in mode_type.values():
		merge_mode.add_item(i)
	merge_mode.select(0)


#============================================================
#  连接信号
#============================================================
func _on_merge_pressed():
	self.merged.emit(Merge.new({
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
		"merge_type": merge_mode.get_selected_id(),
	}))


func _on_resize_select_pressed():
	self.resize_selected.emit(Vector2i( select_texture_width.value, select_texture_height.value ))


func _on_merge_mode_item_selected(index):
	width.editable = (index != MergeMode.MAX_SIZE)
	height.editable = (index != MergeMode.MAX_SIZE)
