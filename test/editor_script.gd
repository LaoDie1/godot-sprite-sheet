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
	
	var texture = preload("res://addons/generate_sprite_sheet/assets/Butcher.png") as Texture2D
	print(texture.get_image().get_format())
	
