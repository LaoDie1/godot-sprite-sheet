#============================================================
#    Editor Script
#============================================================
# - author: zhangxuetu
# - datetime: 2023-04-07 00:54:33
# - version: 4.0
#============================================================
@tool
extends EditorScript


func _run():
	pass
	
#	var data = GenerateSpriteSheetUtil.get_cache_data()
#	print(data)
	
	var roots = Engine.get_main_loop().root.get_child(0).get_children()
	print(roots)
	
	
