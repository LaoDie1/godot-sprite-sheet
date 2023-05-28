#============================================================
#    Sprite Sheet Util
#============================================================
# - author: zhangxuetu
# - datetime: 2023-03-31 20:52:23
# - version: 4.0
#============================================================
## 工具类
class_name SpriteSheetUtil


const CACHE_KEY = "SpriteSheetUtil_get_cache_data"
const TEXTURE_FILTER_KEY = "SpriteSheetUtil_get_texture_filter"

# [ 路径 ]
const CONFIG_DIR = "res://.godot/sprite_sheet"
const CACHE_DATA_FILE_PATH = "res://.godot/sprite_sheet/cache_data.gdata"

## 默认颜色格式
const DEFAULT_FORMAT = Image.FORMAT_RGBA8

## 拖拽数据的类型
const DragType = {
	FileTree = "drag_file",
	Files = "files",
}


## 获取过滤条件
static func get_texture_filter() -> Callable:
	return func(file: String): 
		return file.get_extension() in ["png", "jpg", "bmp", "svg"]


## 如果路径无效，则进行创建
static func if_invalid_make_dir(dir: String) -> void:
	if not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)


## 获取meta数据
static func singleton(key: StringName, default: Callable):
	if Engine.has_meta(key):
		return Engine.get_meta(key)
	else:
		var value = default.call()
		Engine.set_meta(key, value)
		return value


## 获取程序缓存数据
static func get_cache_data() -> Dictionary:
	var data = singleton(CACHE_KEY, func():
		if FileAccess.file_exists(CACHE_DATA_FILE_PATH):
			var bytes = FileAccess.get_file_as_bytes(CACHE_DATA_FILE_PATH)
			if bytes:
				var value = bytes_to_var_with_objects(bytes)
				if value is Dictionary:
					return value
		return {}
	)
	
	return data


## 保存缓存数据，注意防止编辑器打开的节点会保存这个节点
static func save_cache_data():
	if_invalid_make_dir(CACHE_DATA_FILE_PATH.get_base_dir())
	
	var cache_data =_clear_dict_object(get_cache_data().duplicate(true)) 
	if not cache_data.is_empty():
		var bytes = var_to_bytes_with_objects(cache_data)
		var file = FileAccess.open(CACHE_DATA_FILE_PATH, FileAccess.WRITE)
		file.store_buffer(bytes)
		file.flush()
	
	print("[ SpriteSheetUtil ] 保存数据：", cache_data)
	
	Engine.remove_meta(CACHE_KEY)
	Engine.remove_meta(TEXTURE_FILTER_KEY)


static func _clear_dict_object(data):
	if data is Dictionary:
		for key in data:
			if data[key] is Node:
				data[key] = null
			elif data[key] is Dictionary or data[key] is Array:
				_clear_dict_object(data[key])
	
	elif data is Array:
		for i in data:
			_clear_dict_object(i)
	
	return data


## 获取配置数据
static func get_config_data(key: StringName, default : Dictionary = {}) -> Dictionary:
	return get_dict_or_add(get_cache_data(), key, default)


## 获取字典中的字典类型的数据，如果没有则进行新增这个key的空字典值
static func get_dict_or_add(data: Dictionary, key, default: Dictionary = {}) -> Dictionary:
	if data.has(key):
		return data[key]
	else:
		data[key] = default
		return data[key]


## 扫描目录/文件方法
class Scan:
	enum {
		DIRECTORY,
		FILE,
	}
	
	var regex = RegEx.new()
	
	func _init():
		regex.compile("(.*[^\\d])(\\d+)[^\\d]*")
	
	func _sort(a: String, b: String) -> bool:
		var a_index : RegExMatch = regex.search(a)
		if a_index:
			var b_index : RegExMatch = regex.search(b)
			if b_index and a_index.get_string(1) == b_index.get_string(1):
				return int(a_index.get_string(2)) < int(b_index.get_string(2))
		return a < b
	
	func _exec(path: String, list: Array, recursive:bool, type: int):
		var directory := DirAccess.open(path)
		if directory == null:
			printerr("err: ", path)
			return
		
		# 添加
		var dir_list = Array(directory.get_directories()).map(func(dir): return path.path_join(dir) )
		if type == DIRECTORY:
			list.append_array(dir_list)
		else:
			# 文件排序
			var files = Array(directory.get_files())
			files.sort_custom(_sort)
			list.append_array(files.map(func(dir): return path.path_join(dir) ))
		
		# 递归扫描
		if recursive:
			for dir in dir_list:
				_exec(dir, list, recursive, type)
	
	
	static func execute(path: String, list: Array, recursive:bool, type: int):
		var scan = Scan.new()
		scan._exec(path, list, recursive, type)
		


##  扫描目录
##[br]
##[br][code]dir[/code]  扫描的目录
##[br][code]recursive[/code]  是否进行递归扫描
static func scan_directory(dir: String, recursive:= false) -> Array[String]:
	assert(DirAccess.dir_exists_absolute(dir), "没有这个路径")
	var list : Array[String] = []
	Scan.execute(dir, list, recursive, Scan.DIRECTORY)
	return list


##  扫描文件
##[br]
##[br][code]dir[/code]  扫描的目录
##[br][code]recursive[/code]  是否进行递归扫描
static func scan_file(dir: String, recursive:= false) -> Array[String]:
	assert(DirAccess.dir_exists_absolute(dir), "没有这个路径")
	var list : Array[String] = []
	Scan.execute(dir, list, recursive, Scan.FILE)
	return list


##  从一块区域内获取图片数据创建新的图片
##[br]
##[br][code]image[/code]  图片
##[br][code]rect[/code]  区域大小
static func create_texture_by_rect(texture: Texture2D, rect: Rect2i) -> ImageTexture:
	var image = texture.get_image()
	var new_image : Image = Image.create(rect.size.x, rect.size.y, image.has_mipmaps(), image.get_format() )
	new_image.blit_rect(image, rect, Vector2i(0, 0))
	return ImageTexture.create_from_image(new_image)


## 缩放图片
##[br]
##[br][code]texture[/code]  图片
##[br][code]scale[/code]  缩放的倍率
##[br][code]return[/code]  返回缩放后的图片
static func scale_texture(texture: Texture2D, scale: Vector2) -> ImageTexture:
	var new_size = texture.get_size() * scale
	return resize_texture(texture, new_size)


##  重设图片大小
##[br]
##[br][code]texture[/code]  图片
##[br][code]size[/code]  设置的大小
static func resize_texture(texture: Texture2D, size: Vector2i) -> ImageTexture:
	var image = texture.get_image()
	var new_image := resize_image(image, size)
	return ImageTexture.create_from_image(new_image)


##  重设大小
static func resize_image(image: Image, size: Vector2i) -> Image:
	var new_image := Image.new()
	new_image.copy_from(image)
	new_image.resize(size.x, size.y, Image.INTERPOLATE_NEAREST)
	return new_image


## 扫描节点
##[br]
##[br][code]parent[/code]  扫描的祖节点
##[br][code]filter[/code]  过滤节点方法回调，这个方法需要有一个 [Node] 类型的参数并返回一个
##[bool] 值，用来判断是否要添加这个节点。如果不传入则默认扫描出所有节点
##[br][code]return[/code]  返回扫描到的节点列表
static func scan_node(parent: Node, filter: Callable = Callable()) -> Array[Node]:
	var list : Array[Node] = []
	var scan_method : Callable
	if filter.is_valid():
		scan_method = func(callback: Callable, node: Node):
			for child in node.get_children():
				if filter.call(child):
					list.append(child)
			for child in node.get_children():
				callback.call(callback, child)
	else:
		scan_method = func(callback: Callable, node: Node):
			for child in node.get_children():
				list.append(child)
			for child in node.get_children():
				callback.call(callback, child)
	scan_method.call(scan_method, parent)
	return list


## 创建一个新的 Image，不会影响前的图片
static func create_image_from(image: Image) -> Image:
	var new_image : Image = Image.create(image.get_width(), image.get_height(), image.has_mipmaps(), DEFAULT_FORMAT)
	new_image.copy_from(image)
	return new_image


## 替换颜色
static func replace_color(texture: Texture2D, from: Color, to: Color, threshold: float):
	var image = texture.get_image()
	var new_image = Image.create(image.get_width(), image.get_height(), false, DEFAULT_FORMAT)
	var image_size = new_image.get_size()
	var color : Color
	for x in image_size.x:
		for y in image_size.y:
			color = image.get_pixel(x, y)
			if ( abs(color.r - from.r) <= threshold
				and abs(color.g - from.g) <= threshold
				and abs(color.b - from.b) <= threshold
				and abs(color.a - from.a) <= threshold
			):
				new_image.set_pixel(x, y, to)
			else:
				new_image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(new_image)


## 描边
##[br]
##[br][code]texture[/code]  描边的图像
##[br][code]outline_color[/code]  描边颜色
##[br][code]threshold[/code]  透明度阈值范围，如果这个颜色周围的颜色在这个范围内，则进行描边
##[br][code]return[/code]  
static func outline(texture: Texture2D, outline_color: Color, threshold: float = 0.0 ) -> Texture2D:
	var image = texture.get_image()
	var color : Color
	
	# 遍历阈值内的像素
	var empty_pixel_set : Dictionary = {}
	for x in range(0, image.get_size().x):
		for y in range(0, image.get_size().y):
			color = image.get_pixel(x, y)
			if color.a <= threshold:
				empty_pixel_set[Vector2i(x, y)] = null
	
	# 开始描边
	var new_image = create_image_from(texture.get_image())
	var coordinate : Vector2i
	for x in range(0, image.get_size().x):
		for y in range(0, image.get_size().y):
			coordinate = Vector2i(x, y)
			if not empty_pixel_set.has(coordinate):
				# 判断周围上下左右是否有阈值内的透明度像素
				for dir in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					if empty_pixel_set.has(coordinate + dir):
						# 设置新图像的描边
						new_image.set_pixelv(coordinate + dir, outline_color)
	
	return ImageTexture.create_from_image(new_image)


## 加载图片
static func load_image(path: String) -> Texture2D:
	if path.begins_with("res:"):
		return load(path)
	else:
		var image = Image.load_from_file(path)
		return ImageTexture.create_from_image(image)


## 根据节点最大宽度设置宽度
##[br]
##[br][code]controls[/code]  [Control] 类型的节点列表
static func set_width_by_max_width(controls: Array):
	var max_width = 0
	for node in controls:
		(node as Control).custom_minimum_size.x = 0
		(node as Control).size.x = 0
		if max_width < node.size.x:
			max_width = node.size.x
	for node in controls:
		node.custom_minimum_size.x = max_width


##  节点上是否存在鼠标
##[br]
##[br][code]node[/code]  [Control] 类型的节点
static func has_mouse(node: Control) -> bool:
	return Rect2(Vector2(), node.size).has_point(node.get_local_mouse_position())


## 自动注入 unique （唯一名称）节点属性
##[br]
##[br][code]parent[/code]  目标节点，对这个节点的属性进行自动注入节点属性
##[br][code]prefix[/code]  注入的属性的前缀值
##[br]示例：
##[codeblock]
##extends Node
##
##var __init_node__ = InjectUtil.auto_inject(self, "_")
### 当前场景中有 %sprite 、%collision 节点则会自动获取并自动设置下面两个属性
##var _sprite : Sprite2D
##var _collision: Collision
##
##[/codeblock]
static func auto_inject(parent: Node, prefix: String = "", open_err: bool = false):
	var method : Callable = func():
		for data in (parent.get_script() as GDScript).get_script_property_list():
			if data['type'] == TYPE_OBJECT and parent[data['name']] == null:
				var prop = str(data['name']).trim_prefix(prefix)
				if parent.has_node("%" + prop):
					# 注入属性
					var node = parent.get_node_or_null("%" + prop)
					if node:
						parent[data['name']] = node
					else:
						if open_err:
							printerr("没有 ", prop, " 属性相关节点")
	
	if parent.is_inside_tree():
		method.call()
	else:
		parent.tree_entered.connect(method, Object.CONNECT_ONE_SHOT)
	return true



