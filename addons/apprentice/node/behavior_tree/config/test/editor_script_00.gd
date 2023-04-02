# editor_script_00.gd
@tool
extends EditorScript


func _run():
	
#	print(FileUtil.get_relative_file_by_object_path(self, "/doc/document.txt"))
	
	var path = "res://addons/apprentice/node/behavior_tree/util/parse/test/doc/document.txt"
	
	for child in EditorUtil.get_edited_scene_root().get_children():
		child.queue_free()
	
	var document := Document.parse_by_path(
		path, EditorUtil.get_edited_scene_root(), {
			"objects": {
				"readable_name": true
			}
		}, 
		func(doc: String):
			return doc.strip_edges()
	) as Document
	
	
	
#	JsonUtil.print_stringify(JsonUtil.object_to_dict(document.struct_root), "\t")
	
	

