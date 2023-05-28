#============================================================
#    Pending Handle
#============================================================
# - author: zhangxuetu
# - datetime: 2023-04-02 18:11:15
# - version: 4.0
#============================================================
## 待处理操作
@tool
class_name SpriteSheet_PendingHandle
extends MarginContainer


signal merged(data: Merge)


## 合并方式
enum MergeMode {
	SCALE,		# 缩放图像到指定大小后合并
	CUT,		# 按照定宽度合并图片，剪切掉超出的部分
	MAX_SIZE,	# 按照最大宽高设置图片
	FLOW,		# 流式排列，按照不同大小图片逐个排列合并
}

const MergeModeItem : Dictionary = {
	MergeMode.SCALE: "SCALE_TO_SPECIFIED_SIZE",
	MergeMode.CUT: "CUT_OFF_THE_EXCESS",
	MergeMode.MAX_SIZE: "SET_TO_LARGEST_BLOCK_SIZE",
	MergeMode.FLOW: "FLOW_ARRANGE_MERGE"
}

## 每个单元格位置的图片的排列位置
enum MergePos {
	CENTER_LEFT,
	TOP_LEFT,
	CENTER_TOP,
	TOP_RIGHT,
	CENTER_RIGHT,
	BOTTOM_RIGHT,
	CENTER_BOTTOM,
	BOTTOM_LEFT,
	CENTER,
}

const MergePosItem : Dictionary = {
	MergePos.CENTER_LEFT: "左",
	MergePos.TOP_LEFT: "左上",
	MergePos.CENTER_TOP: "上",
	MergePos.TOP_RIGHT: "右上",
	MergePos.CENTER_RIGHT: "右",
	MergePos.BOTTOM_RIGHT: "右下",
	MergePos.CENTER_BOTTOM: "下",
	MergePos.BOTTOM_LEFT: "左下",
	MergePos.CENTER: "居中",
}


var __init_node__ = SpriteSheetUtil.auto_inject(self, "")

var merge_mode : OptionButton
var max_column_label : Label
var max_column : SpinBox
var cell_size_label : Label
var cell_size : BoxContainer
var max_width_label : Label
var max_width : SpinBox
var separator : BoxContainer
var margin : GridContainer
var merge_cell_pos_label : Label
var merge_cell_pos : OptionButton


#============================================================
#  合并操作
#============================================================
# 合并功能
class Merge:
	var max_column : int
	var width : int
	var height: int
	var max_width : int
	var max_height : int
	var left_separation : int
	var top_separation : int
	var left_margin : int
	var right_margin : int
	var top_margin : int 
	var down_margin : int 
	
	var merge_type : int
	var merge_cell_pos : int
	
	
	func _init(data: Dictionary):
		for prop in data:
			set(prop, data[prop])
	
	## 执行合并
	func execute(texture_list: Array[Texture2D]) -> Texture2D:
		if merge_type == MergeMode.FLOW:
			# 流式图片合并
			return _flow(texture_list)
		else:
			return _normal(texture_list)
	
	
	func _normal(texture_list: Array[Texture2D]) -> Texture2D:
		# 其他类型合并
		if texture_list.size() < max_column:
			max_column = texture_list.size()
		
		if merge_type in [
			MergeMode.SCALE,
			MergeMode.CUT,
		]:
			if width <= 0 or height <= 0:
				SpriteSheetMain.show_message("宽度和高度不能为 0！")
				return
		
		var max_row : int = ceil(texture_list.size() / float(max_column))
		
		# 每个图块大小
		var sub_image_size : Vector2i = Vector2i(0, 0)
		if merge_type == MergeMode.MAX_SIZE:
			# 找到最大宽和高
			var idx : int = 0
			for texture in texture_list:
				if sub_image_size.x < texture.get_size().x:
					sub_image_size.x = texture.get_size().x
				if sub_image_size.y < texture.get_size().y:
					sub_image_size.y = texture.get_size().y
			
		else:
			# 设置的宽高参数
			sub_image_size = Vector2i(width, height)
		
		# 每个图块包含边距的大小
		var cell_size =  Vector2i(
			(sub_image_size.x + left_separation), 
			(sub_image_size.y + top_separation)
		)
		
		# 整张图片大小
		var image_width : int = ( left_margin + right_margin + cell_size.x * max_column )
		var image_height : int  = ( top_margin + down_margin + cell_size.y * max_row )
		var image_format = texture_list[0].get_image().get_format()
		var merge_image : Image = Image.create(image_width, image_height, false, image_format)
		
		# 开始合并
		var draw_pos : Vector2i
		var x : int
		var y : int 
		var idx = 0
		var image : Image
		for texture in texture_list:
			# 计算图片所在坐标位置
			x = idx % max_column
			y = idx / max_column
			draw_pos = Vector2i(x, y) * cell_size
			image = texture.get_image()
			if merge_type == MergeMode.SCALE:
				# 缩放到指定大小
				image = SpriteSheetUtil.resize_image(image, sub_image_size)
			
			# 设置位置
			var offset_pos : Vector2i = draw_pos
			if merge_type == MergeMode.MAX_SIZE or merge_type == MergeMode.CUT:
				var diff_size : Vector2i = cell_size - image.get_size()
				# 左和上为默认位置，无需 if 判断
				if diff_size != Vector2i():
					match merge_cell_pos:
						MergePos.CENTER_LEFT:
							offset_pos.y += diff_size.y / 2
						MergePos.CENTER_BOTTOM:
							offset_pos.x += diff_size.x / 2
							offset_pos.y += diff_size.y
						MergePos.CENTER_RIGHT:
							offset_pos.x += diff_size.x
							offset_pos.y += diff_size.y / 2
						MergePos.CENTER_TOP:
							offset_pos.x += diff_size.x / 2
						MergePos.CENTER:
							offset_pos += diff_size / 2
						MergePos.TOP_RIGHT:
							offset_pos.x += diff_size.x
						MergePos.BOTTOM_LEFT:
							offset_pos.y += diff_size.y
						MergePos.BOTTOM_RIGHT:
							offset_pos += diff_size
					
			
			merge_image.blit_rect(image, Rect2i(Vector2i(left_margin, top_margin), cell_size), offset_pos)
			idx += 1
		
		# 返回合并的图像
		return ImageTexture.create_from_image(merge_image)
	
	
	func _flow(texture_list: Array[Texture2D]) -> Texture2D:
		if max_width <= 0:
			SpriteSheetMain.show_message("没有设置最大宽度")
			return null
		
		# 流式方式合并
		var leftmost = left_margin + left_separation
		var separation_x = left_separation
		var separation_y = top_separation
		
		var merge_image : Image = Image.create(max_width, 16384, false, Image.FORMAT_RGBA8)
		var pos : Vector2i = Vector2i(leftmost, top_margin + top_separation)
		var next_y : int
		var image : Image
		var image_size : Vector2i
		var texture : Texture2D
		for idx in texture_list.size():
			texture = texture_list[idx]
			image = texture.get_image()
			image_size = image.get_size()
			
			# 判断是否超出区域
			if pos.x != leftmost:
				if pos.x + image_size.x > max_width and idx < texture_list.size():
					pos.x = leftmost
					pos.y = next_y
			
			# 合并
			merge_image.blit_rect(image, Rect2i(Vector2i(), image_size), pos)
			
			# 自动偏移
			pos.x += image_size.x + separation_x
			if next_y < pos.y + image_size.y + top_separation:
				next_y = pos.y + image_size.y + separation_y
		
		var rect = Rect2i(Vector2i(), Vector2i(max_width, next_y))
		return ImageTexture.create_from_image(merge_image.get_region(rect))
	


#============================================================
#  内置
#============================================================
func _ready():
	# 合并方式
	var merge_mode_node = %merge_mode as OptionButton
	merge_mode_node.clear()
	for i in MergeModeItem.values():
		merge_mode_node.add_item(i)
	merge_mode_node.selected = 0
	
	# 合并的每个图块的位置
	merge_cell_pos.clear()
	var default := preload("cell_pos_theme.theme") as Theme
	var keys = MergePos.keys()
	for key in MergePosItem:
		var value = MergePosItem[key]
		var dir_prop = "ControlAlign" + str(keys[key]).capitalize().replace(" ", "")
		var texture = default.get_icon(dir_prop, "EditorIcons")
		merge_cell_pos.add_icon_item(texture, value)
	merge_cell_pos.select(1)
	
	_on_merge_mode_item_selected(0)



#============================================================
#  连接信号
#============================================================
func _on_merge_pressed():
	var margin_rect := Rect2i(margin.get_value())
	self.merged.emit(Merge.new({
		"merge_type": merge_mode.get_selected_id(),
		"max_column": max_column.value,
		"width": cell_size.get_value().x,
		"height": cell_size.get_value().y,
		"max_width": max_width.value,
		"left_separation": separator.get_value().x,
		"top_separation": separator.get_value().y,
		"left_margin": margin_rect.position.x,
		"right_margin": margin_rect.size.x,
		"top_margin": margin_rect.position.y,
		"down_margin": margin_rect.size.y,
		"merge_cell_pos": merge_cell_pos.selected,
	}))


func _on_merge_mode_item_selected(index):
	# 可见性的节点
	var visible_node_list : Array = [
		max_width_label, max_width, cell_size_label, cell_size, max_column_label, max_column, 
		merge_cell_pos_label, merge_cell_pos,
	]
	# 不可见的节点（去掉可见的节点）
	var no_visi_map = {
		MergeMode.SCALE: [
			merge_cell_pos_label, merge_cell_pos, max_width_label, max_width,
		],
		MergeMode.CUT: [
			max_width_label, max_width,
		],
		MergeMode.MAX_SIZE: [
			cell_size_label, cell_size, max_width_label, max_width,
		],
		MergeMode.FLOW: [
			merge_cell_pos_label, merge_cell_pos,
			cell_size_label, cell_size, max_column_label, max_column
		],
	}
	# 更新状态
	var no_visible_node_list : Array = no_visi_map.get(index, [])
	for node in no_visible_node_list:
		node['visible'] = false
	for node in visible_node_list:
		if not no_visible_node_list.has(node):
			node['visible'] = true
	
