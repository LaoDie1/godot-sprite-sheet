#============================================================
#    Platfrom Map
#============================================================
# - author: zhangxuetu
# - datetime: 2023-03-28 17:07:19
# - version: 4.0
#============================================================
@tool
extends EditorScript


func _run():
	pass
	
	var root = EditorUtil.get_edited_scene_root()
	
	var room_count : int = 10
	var rnd_room_size = RandomValue.new()
	rnd_room_size.value = 5
	rnd_room_size.max_value = 20
	
	# 开始生成
	var curr_map_rect : Rect2i = Rect2i()
	var last_pos : Vector2i = Vector2i()
	var last_size : Vector2i = Vector2i()
	for i in room_count:
		var v = int(rnd_room_size.get_value())
		var size : Vector2i = Vector2i(v, v)
		
		# 创建房间
		var room = ColorRect.new()
		room.custom_minimum_size = size
		root.add_child(room)
		
		# 设置位置
		room.global_position = last_pos + last_size
		
		# 记录上次信息
		last_pos = room.global_position
		last_size = size
		
		
		

