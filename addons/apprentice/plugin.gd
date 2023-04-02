#============================================================
#    Plugin
#============================================================
# - datetime: 2022-08-28 23:28:30
#============================================================
@tool
extends EditorPlugin


const AUTOLOAD_CONFIG = "AutoLoadConfig"
const AutoLoadConfig = preload("config/auto_load_config.gd")


var __added_type := {}


func _enter_tree() -> void:
	var scan_file : Callable = func(path: String, list: Array, callback: Callable):
		var directory := DirAccess.open(path)
		if directory == null:
			printerr("error: ", path)
			return
		directory.list_dir_begin()
		# 遍历文件
		var dir_list := []
		var file_list := []
		var file := ""
		file = directory.get_next()
		while file != "":
			# 目录
			if directory.current_is_dir() and not file.begins_with("."):
				if not FileAccess.file_exists(path.path_join(".ignorescan")):
					dir_list.append( path.path_join(file) )
			# 文件
			elif not directory.current_is_dir() and not file.begins_with("."):
				file_list.append( path.path_join(file) )
			file = directory.get_next()
		
		# 添加
#		list.append_array(dir_list)
		list.append_array(file_list)
		# 递归扫描
		for dir in dir_list:
			callback.call(dir, list, callback)
	
	# 扫描并加载脚本
	var script_list : Array[String] = []
	scan_file.call( get_script().resource_path.get_base_dir().path_join("node"), script_list, scan_file )
	for path in script_list:
		if path.get_extension() == "gd":
			__added_type[path.get_file().get_basename().capitalize().replace(" ", "")] = load(path)
	
	# 添加自定义类型
	for s_name in __added_type:
		var script : Script = __added_type[s_name]
		add_custom_type(
			s_name, 
			script.get_instance_base_type(), 
			script, 
			get_editor_interface().get_base_control().get_theme_icon(script.get_instance_base_type(), "EditorIcons")
		)
	
	# 自动加载配置
	var current_path =  (get_script() as Resource).resource_path.get_base_dir() as String
	var config_path = current_path.path_join("config/auto_load_config.gd")
	add_autoload_singleton(AUTOLOAD_CONFIG, config_path)
	
	if not DirAccess.dir_exists_absolute(AutoLoadConfig.CONFIG_PATH):
		DirAccess.make_dir_recursive_absolute(AutoLoadConfig.CONFIG_PATH)
		get_editor_interface().get_resource_filesystem().scan()
		
		var to = AutoLoadConfig.CONFIG_PATH.path_join("example_config.gd")
		DirAccess.copy_absolute(current_path.path_join("config/example_config.gd"), to)
	
	


func _exit_tree() -> void:
	for s_name in __added_type:
		remove_custom_type(s_name)
	
	remove_autoload_singleton(AUTOLOAD_CONFIG)
