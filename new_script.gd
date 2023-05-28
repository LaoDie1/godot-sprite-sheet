#============================================================
#    New Script
#============================================================
# - author: zhangxuetu
# - datetime: 2023-05-28 23:29:07
# - version: 4.0
#============================================================
@tool
extends EditorScript


func _run():
	var path = "res://.godot/sprite_sheet/cache_data.gdata"
	var data = SpriteSheetUtil.get_cache_data()
	print(data)
	
	

