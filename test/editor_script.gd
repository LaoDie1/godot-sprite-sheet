#============================================================
#    Editor Script
#============================================================
# - author: zhangxuetu
# - datetime: 2023-04-05 22:03:45
# - version: 4.0
#============================================================
@tool
extends EditorScript


func _run():
	pass
	
	var path = "res://test.gdata"
	
#	var write_data = {
#		a = 10,
#		image = preload("res://icon.svg"),
#	}
#	var r = FileUtil.write_as_bytes(path, write_data)
#	print(r)
	
	var data = FileUtil.read_as_bytes(path)
	print(data)
	
	

