#============================================================
#    File Utils
#============================================================
# - datetime: 2022-08-23 18:26:26
#============================================================

##  文件工具类
class_name FileUtil


class Scan:
	enum {
		DIRECTORY,
		FILE,
	}
	
	static func method(path: String, list: Array, recursive:bool, type):
		var directory := DirAccess.open(path)
		if directory == null:
			printerr("err: ", path)
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
				dir_list.append( path.path_join(file) )
			# 文件
			elif not directory.current_is_dir() and not file.begins_with("."):
				file_list.append( path.path_join(file) )
			
			file = directory.get_next()
		# 添加
		if type == DIRECTORY:
			list.append_array(dir_list)
		else:
			list.append_array(file_list)
		# 递归扫描
		if recursive:
			for dir in dir_list:
				method(dir, list, recursive, type)


##  保存为文本文件
##[br]
##[br][code]file_path[/code]  文件路径
##[br][code]txt[/code]  文本内容
##[br]
##[br][code]return[/code]  返回是否保存成功
static func write_as_text(file_path:String, text:String) -> bool:
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(text)
		file = null
		return true
	return false


## 文件是否存在
static func file_exists(file_path: String) -> bool:
	return FileAccess.file_exists(file_path)


##  保存为CSV文件
##[br]
##[br][code]file_path[/code]  文件路径
##[br][code]list[/code]  每行的表格项
##[br][code]delim[/code]  分隔符。一般使用 [code],[/code] 作为分隔符
static func write_as_csv(file_path:String, list: Array[PackedStringArray], delim: String) -> bool:
	assert(len(delim) == 1, "分隔符长度必须为1！")
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		for i in list:
			file.store_csv_line(i, delim)
		file = null
		return true
	return false


##  读取文件
##[br]
##[br][code]file_path[/code]  文件路径
##[br][code]skip_cr[/code]  跳过 \r CR 字符
## If skip_cr is true, carriage return characters (\r, CR) will be ignored when parsing the UTF-8, so that only line feed characters (\n, LF) represent a new line (Unix convention).
static func read_as_text(file_path: String, skip_cr: bool = false):
	if FileAccess.file_exists(file_path):
		var file := FileAccess.open(file_path, FileAccess.READ)
		if file:
			var text = file.get_as_text(skip_cr)
			file = null
			return text

## 写入数据。与其他写入不同的是，这个会将数据转为字符串之后保存
static func write_data(data, file_path: String):
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(var_to_str(data))
		return true
	return false


## 读取数据。读取 [method write_data] 保存的文件数据
static func read_data(file_path):
	if FileAccess.file_exists(file_path):
		var file := FileAccess.open(file_path, FileAccess.READ)
		if file:
			var data = file.get_as_text(file_path)
			file = null
			return str_to_var(data)


##  保存为变量数据
##[br]
##[br][code]file_path[/code]  文件路径
##[br][code]data[/code]  数据
##[br][code]full_objects[/code]  如果是 true，则允许编码对象（并且可能包含代码）。
static func write_as_var(file_path: String, data, full_objects: bool = false):
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_var(data, full_objects)
		file = null
		return true
	return false


##  读取 var 数据
static func read_as_var(file_path: String, allow_objects: bool = false):
	if FileAccess.file_exists(file_path):
		var file := FileAccess.open(file_path, FileAccess.READ)
		if file:
			var data = file.get_var(allow_objects)
			file = null
			return data


## 转为 JSON 写入文件
static func write_as_json(file_path: String, data):
	var d = JSON.stringify(data)
	write_as_text(file_path, d)


##  读取 JSON 文件并解析
##[br]
##[br][code]file_path[/code]  文件路径
##[br][code]skip_cr[/code]  跳过 \r CR 字符
static func read_as_json(
	file_path: String, 
	skip_cr: bool = false
):
	var json = read_as_text(file_path, skip_cr)
	if json != null:
		return JSON.parse_string(json)

##  扫描目录
static func scan_directory(dir: String, recursive:= false) -> Array[String]:
	assert(DirAccess.dir_exists_absolute(dir), "没有这个路径")
	var list : Array[String] = []
	Scan.method(dir, list, recursive, Scan.DIRECTORY)
	return list


##  扫描文件
static func scan_file(dir: String, recursive:= false) -> Array[String]:
	assert(DirAccess.dir_exists_absolute(dir), "没有这个路径")
	var list : Array[String] = []
	Scan.method(dir, list, recursive, Scan.FILE)
	return list


## 获取对象文件路径，如果返回为空，则没有
static func get_object_file(object: Object) -> String:
	if object:
		if object is Resource:
			return object.resource_path
		else:
			var script = object.get_script() as Script
			if script:
				return script.resource_path
	return ""


## 获取相对于这个对象的文件路径
static func get_relative_file_by_object_path(object: Object, file_name: String) -> String:
	var path = get_object_file(object)
	if path:
		return path.get_base_dir().path_join(file_name)
	return ""
	


##  保存点为场景文件
##[br]
##[br][code]node[/code]  节点
##[br][code]path[/code]  保存到的路径
##[br][code]save_flags[/code]  保存掩码，详见：[enum ResourceSaver.SaverFlags]
static func save_scene(node: Node, path: String, save_flags: int = ResourceSaver.FLAG_NONE):
	var scene = PackedScene.new()
	scene.pack(node)
	return ResourceSaver.save(scene, path, save_flags)

