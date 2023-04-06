#============================================================
#    Generate Sprite Sheet Util
#============================================================
# - author: zhangxuetu
# - datetime: 2023-03-31 20:52:23
# - version: 4.0
#============================================================
## 工具类
class_name GenerateSpriteSheetUtil


## 默认格式
const DEFAULT_FORMAT = Image.FORMAT_RGBA8

const CONFIG_DIR = "res://.godot/generate_sprite_sheet"
const CACHE_DATA_FILE_PATH = CONFIG_DIR + "/cache_data.gdata"

const DragType = {
	FileTree = "drag_file",
}


## 如果路径无效，则进行创建
static func if_invalid_make_dir(dir: String) -> void:
	if not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)


## 获取meta数据
static func get_meta_data(key: StringName, default):
	if Engine.has_meta(key):
		return Engine.get_meta(key)
	else:
		Engine.set_meta(key, default)
	return default


## 获取程序缓存数据
static func get_cache_data() -> Dictionary:
	var data = {}
	if FileAccess.file_exists(CACHE_DATA_FILE_PATH):
		var bytes = FileAccess.get_file_as_bytes(CACHE_DATA_FILE_PATH)
		data = bytes_to_var_with_objects(bytes)
	if data == null:
		data = {}
	return data


## 保存缓存数据
static func save_cache_data():
	if_invalid_make_dir(CONFIG_DIR)
	var file = FileAccess.open(CACHE_DATA_FILE_PATH, FileAccess.WRITE)
	var cache_data = get_cache_data()
	var bytes = var_to_bytes_with_objects(cache_data)
	file.store_buffer(bytes)
	file = null


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


##  扫描目录
##[br]
##[br][code]dir[/code]  扫描的目录
##[br][code]recursive[/code]  是否进行递归扫描
static func scan_directory(dir: String, recursive:= false) -> Array[String]:
	assert(DirAccess.dir_exists_absolute(dir), "没有这个路径")
	var list : Array[String] = []
	Scan.method(dir, list, recursive, Scan.DIRECTORY)
	return list


##  扫描文件
##[br]
##[br][code]dir[/code]  扫描的目录
##[br][code]recursive[/code]  是否进行递归扫描
static func scan_file(dir: String, recursive:= false) -> Array[String]:
	assert(DirAccess.dir_exists_absolute(dir), "没有这个路径")
	var list : Array[String] = []
	Scan.method(dir, list, recursive, Scan.FILE)
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

## 复制一个新的 Image，不会影响前的图片
static func copy_image(image: Image) -> Image:
	var new_image : Image = Image.create(image.get_width(), image.get_height(), image.has_mipmaps(), DEFAULT_FORMAT)
	new_image.copy_from(image)
	return new_image


## 替换颜色
static func replace_color(texture: Texture2D, from: Color, to: Color, threshold: float):
	var image = copy_image(texture.get_image())
	var image_size = image.get_size()
	var color : Color
	for x in image_size.x:
		for y in image_size.y:
			color = image.get_pixel(x, y)
			if ( abs(color.r - from.r) <= threshold
				and abs(color.g - from.g) <= threshold
				and abs(color.b - from.b) <= threshold
				and abs(color.a - from.a) <= threshold
			):
				image.set_pixel(x, y, to)
	return ImageTexture.create_from_image(image)


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
	for x in range(1, image.get_size().x - 1):
		for y in range(1, image.get_size().y - 1):
			color = image.get_pixel(x, y)
			if color.a <= threshold:
				empty_pixel_set[Vector2i(x, y)] = null
	
	# 开始描边
	var new_image = copy_image(texture.get_image())
	var coordinate : Vector2i
	for x in range(1, image.get_size().x - 1):
		for y in range(1, image.get_size().y - 1):
			coordinate = Vector2i(x, y)
			if not empty_pixel_set.has(coordinate):
				color = image.get_pixel(x, y)
				# 判断周围上下左右是否有阈值内的透明度像素
				for dir in [Vector2i(x - 1, y), Vector2i(x + 1, y), Vector2i(x, y - 1), Vector2i(x, y + 1)]:
					if empty_pixel_set.has(dir):
						# 设置新图像的描边
						new_image.set_pixelv(dir, outline_color)
	
	return ImageTexture.create_from_image(new_image)


## 获取过滤条件
static func get_texture_filter() -> Callable:
	const KEY = "GenerateSpriteSheetUtil_get_texture_filter"
	return get_meta_data(KEY, func(file: String):
		return file.get_extension() in ["png", "jpg", "svg"]
	)


## 加载图片
static func load_image(path: String) -> Texture2D:
	if path.begins_with("res:"):
		return load(path)
	else:
		var image = Image.load_from_file(path)
		return ImageTexture.create_from_image(image)


