#============================================================
#    Init Project Folder
#============================================================
# - datetime: 2022-09-27 21:33:21
#============================================================
@tool
extends EditorPlugin


const MENU_NAME = "初始化项目目录"


func _enter_tree() -> void:
	add_tool_menu_item(MENU_NAME, func():
		var dir_list = [
			"/src",
			"/src/main",
			"/src/main/assets",
			"/src/main/assets/texture",
			"/src/main/assets/texture/role",
			"/src/main/assets/texture/vfx",
			"/src/main/assets/texture/ui",
			"/src/main/assets/sound",
			"/src/main/assets/font",
			"/src/main/common",
			"/src/main/common/autoload",
			"/src/main/common/util",
			"/src/main/component",
			"/src/main/scene",
			"/src/main/scene/role",
			"/src/main/scene/ui",
			
			"/src/test",
		]
		
		print("初始化目录菜单，已创建目录：")
		for dir in dir_list:
			dir = "res:/" + dir
			if not DirAccess.dir_exists_absolute(dir):
				DirAccess.make_dir_recursive_absolute(dir)
				print("  ", dir)
		
		get_editor_interface().get_resource_filesystem().scan()
		
	)
	


func _exit_tree() -> void:
	remove_tool_menu_item(MENU_NAME)
