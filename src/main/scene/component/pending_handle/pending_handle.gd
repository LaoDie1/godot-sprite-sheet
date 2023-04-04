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
@onready var width_label = %width_label
@onready var height_label = %height_label
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


## 合并方式
enum MergeMode {
	SCALE,		# 缩放图像到指定大小后合并
	CUT,		# 按照定宽度合并图片，剪切掉超出的部分
	MAX_SIZE,	# 按照最大宽高设置图片
	FLOW,		# 流式排列，按照不同大小图片逐个排列合并
}


class Merge:
	var max_column : int
	var width : int
	var height: int
	var max_width : int
	var max_height : int
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
				GenerateSpriteSheetMain.show_message("宽度和高度不能为 0！")
				return
		
		var max_row : int = ceil(texture_list.size() / float(max_column))
		
		# 每个图块大小
		var sub_image_size : Vector2i = Vector2i(0, 0)
		if merge_type == MergeMode.MAX_SIZE:
			# 找到最大宽和高
			var idx : int = 0
			var texture : Texture2D
			for y in max_row:
				for x in max_column:
					if idx < texture_list.size():
						texture = texture_list[idx]
						idx += 1
						if sub_image_size.x < texture.get_size().x:
							sub_image_size.x = texture.get_size().x
						if sub_image_size.y < texture.get_size().y:
							sub_image_size.y = texture.get_size().y
						
					else:
						break
				if idx < texture_list.size():
					break
			
		else:
			# 设置的宽高参数
			sub_image_size = Vector2i(width, height)
		
		# 每个图块包含边距的大小
		var cell_size =  Vector2i(
			(sub_image_size.x + left_separation + right_separation), 
			(sub_image_size.y + top_separation + down_separation)
		)
		
		# 整张图片大小
		var image_width : int = ( left_margin + right_margin + cell_size.x * max_column )
		var image_height : int  = ( top_margin + down_margin + cell_size.y * max_row )
		var image_format = texture_list[0].get_image().get_format()
		var merge_image : Image = Image.create(image_width, image_height, false, image_format)
		
		# 开始合并
		var coordinate : Vector2i
		var x : int
		var y : int 
		var idx = 0
		var image : Image
		for texture in texture_list:
			x = idx % max_column
			y = idx / max_column
			coordinate = Vector2i(x, y) * cell_size
			image = texture.get_image()
			if merge_type == MergeMode.SCALE:
				# 缩放到指定大小
				image = GenerateSpriteSheetUtil.resize_image(image, sub_image_size)
			merge_image.blit_rect(image, Rect2i(Vector2i(left_margin, top_margin), cell_size), coordinate)
			idx += 1
		
		# 返回合并的图像
		return ImageTexture.create_from_image(merge_image)
	
	
	func _flow(texture_list: Array[Texture2D]) -> Texture2D:
		if max_width <= 0:
			GenerateSpriteSheetMain.show_message("没有设置最大宽度")
			return null
		
		# 流式方式合并
		var leftmost = left_margin + left_separation
		var separation_x = left_separation + right_separation
		var separation_y = top_separation + down_separation
		
		var merge_image : Image = Image.create(max_width, 16384, false, Image.FORMAT_RGBA8)
		var pos : Vector2i = Vector2i(leftmost, top_margin + top_separation)
		var next_y : int
		var image : Image
		var image_size : Vector2i
		texture_list.reverse()
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
	var mode_type : Dictionary = {
		MergeMode.SCALE: "缩放到指定大小",
		MergeMode.CUT: "剪切掉多余部分",
		MergeMode.MAX_SIZE: "图块设为最大图像的大小",
		MergeMode.FLOW: "流式排列合并"
	}
	for i in mode_type.values():
		merge_mode.add_item(i)
	merge_mode.selected = 0



#============================================================
#  连接信号
#============================================================
func _on_merge_pressed():
	self.merged.emit(Merge.new({
		"max_column": max_column.value,
		width.name: width.value,
		height.name: height.value,
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
	# 设置对应的节点的是否可编辑映射数据
	var node_map : Dictionary = {
		width: null,
		height: null,
		max_column: null,
	}
	match index:
		MergeMode.SCALE:
			pass
		MergeMode.CUT:
			pass
		MergeMode.MAX_SIZE:
			node_map[width] = false
			node_map[height] = false
		
		MergeMode.FLOW:
			node_map[height] =  false
			node_map[max_column] = false
	
	# 修改是否可编辑状态
	for node in node_map:
		var editable = node_map[node]
		if editable == null:
			editable = true
		node["editable"] = editable
	
	# 其他更新
	if index == MergeMode.FLOW:
		width_label.text = "最大宽度："
		height_label.text = "最大高度："
		width.name = "max_width"
		height.name = "max_height"
	else:
		width_label.text = "宽度："
		height_label.text = "高度："
		width.name = "width"
		height.name = "height"
	
