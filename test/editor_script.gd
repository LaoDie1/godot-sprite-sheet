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
	
	var dir = DirAccess.open("res://")
	print( dir.get_directories() )
	
	
	
