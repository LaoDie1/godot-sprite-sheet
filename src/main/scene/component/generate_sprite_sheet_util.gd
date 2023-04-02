#============================================================
#    Generate Sprite Sheet Util
#============================================================
# - author: zhangxuetu
# - datetime: 2023-03-31 20:52:23
# - version: 4.0
#============================================================
## 工具类
class_name GenerateSpriteSheetUtil


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
