#============================================================
#    Texture Util
#============================================================
# - datetime: 2023-02-12 00:16:54
#============================================================
## 与 [Texture] 资源相关处理的方法
class_name TextureUtil



## 图片是否是空的
static func is_empty(image: Image) -> bool:
	return image.is_empty() or image.get_used_rect().size == Vector2i.ZERO


## 区域是否为空图像
static func is_empty_in_region(image: Image, region: Rect2i) -> bool:
	return is_empty(image.get_region(region))


##  根据序列列表
##[br]
##[br][code]list[/code]  图片序列列表
##[br][code]return[/code]  
static func generate_sprite_frames(list: Array[Array]) -> SpriteFrames:
	var sprite_frames := SpriteFrames.new()
	sprite_frames.remove_animation("default")
	var idx = 0
	for sequence in list:
		var animation_name = "anim_%03d" % idx
		sprite_frames.add_animation(animation_name)
		for atlas_texture in sequence:
			# 如果图片区域为空，则不继续添加后面的列
			if is_empty(atlas_texture.get_image()):
				break
			sprite_frames.add_frame(animation_name, atlas_texture)
			sprite_frames.set_animation_loop(animation_name, false)
			sprite_frames.set_animation_speed(animation_name, 8)
		idx += 1
	
	return sprite_frames


##  根据图片划分成表格生成 [SpriteFrames]
##[br]
##[br][code]texture[/code]  切分的图片
##[br][code]cut_size[/code]  切割的格数大小
##[br][code]cut_direction[/code]  切割方向。详见: [method gene_atlas_textures_by_cell_size]
static func generate_sprite_frames_by_cut_size(
	texture: Texture2D, 
	cut_size: Vector2i, 
	cut_direction: int = VERTICAL
) -> SpriteFrames:
	var cell_size = texture.get_image().get_size() / cut_size
	return gene_frames_by_cell_size(texture, cell_size, cut_direction)


##  固定生成的图片大小生成 [SpriteFrames]
##[br]
##[br][code]texture[/code]  切分的图片
##[br][code]cell_size[/code]  切分后每个图片的大小
##[br][code]cut_direction[/code]  切割方向。详见: [method gene_atlas_textures_by_cell_size]
static func gene_frames_by_cell_size(
	texture: Texture2D, 
	cell_size: Vector2i, 
	cut_direction: int = VERTICAL
) -> SpriteFrames:
	var list = gene_atlas_textures_by_cell_size(texture, cell_size, cut_direction)
	var sprite_frames = generate_sprite_frames(list)
	print("[ TextureUtil ] ", "已生成 SpriteFrames：", sprite_frames)
	return sprite_frames


##  生成 [AtlasTexture] 图片序列列表
##[br]
##[br][code]texture[/code]  生成的贴图
##[br][code]cell_size[/code]  每个图片的大小
##[br][code]cut_direction[/code]  切割方向
##[br]    - [constant @GlobalScope.HORIZONTAL] 水平切割，从左到右的顺序获取一组图片序列
##[br]    - [constant @GlobalScope.VERTICAL] 垂直切割，从上到下的顺序获取一组图片序列
static func gene_atlas_textures_by_cell_size(
	texture: Texture2D, 
	cell_size: Vector2i, 
	cut_direction: int = HORIZONTAL
) -> Array[Array]:
	var image = texture.get_image() as Image
	var grid_size = image.get_size() / cell_size
	
	var x_dir : int
	var y_dir : int
	if cut_direction == HORIZONTAL:
		x_dir = 0
		y_dir = 1
	else:
		x_dir = 1
		y_dir = 0
	
	var list : Array[Array] = []
	for y in grid_size[y_dir]:
		var sequence = []
		for x in grid_size[x_dir]:
			var size = Vector2i()
			size[x_dir] = x
			size[y_dir] = y
			var atlas_texture = gene_atlas_texture(texture, Rect2i(size * cell_size, cell_size))
			sequence.append(atlas_texture)
		list.append(sequence)
	
	return list


## 将那片区域图像转为 [AtlasTexture] 资源
static func gene_atlas_texture(texture: Texture2D, region: Rect2i) -> AtlasTexture:
	var atlas_texture := AtlasTexture.new()
	atlas_texture.atlas = texture
	atlas_texture.region = region
	return atlas_texture


## [Texture2D] 转为多边形的点，返回每个区域生成多边形的点的列表
static func gene_polygon_points(texture: Texture2D) -> Array[PackedVector2Array]:
	var bit_map = BitMap.new()
	bit_map.create_from_image_alpha( texture.get_image() )
	return bit_map.opaque_to_polygons( Rect2i(Vector2i.ZERO, bit_map.get_size()) )
	

## 获取 [AnimatedSprite2D] 当前放的动画的帧的 [Texture]
static func get_animated_sprite_current_frame(animated_sprite: AnimatedSprite2D) -> Texture2D:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return null
	var sprite_frames = animated_sprite.sprite_frames as SpriteFrames
	var animation = animated_sprite.animation
	if animated_sprite.is_playing():
		var frame = animated_sprite.frame
		return sprite_frames.get_frame_texture(animation, frame)
	else:
		return sprite_frames.get_frame_texture(animation, 0)


## 修改图片的 alpha 值
static func set_image_alpha(image: Image, alpha: float) -> Image:
	var image_size = image.get_size()
	var color : Color
	for x in image_size.x:
		for y in image_size.y:
			color = image.get_pixel(x, y)
			if color.a > 0:
				# 修改图片的 alpha 值
				color.a = alpha
				image.set_pixel(x, y, color)
	return image


## 图片混合。根据 b_ratio 修改图片的 alpha 展现 b 图片颜色清晰度
static func blend_image_alpha(a: Image, b: Image, b_ratio: float) -> Image:
	assert(b_ratio >= 0 and b_ratio <= 1.0, "比值必须在 0 - 1 之间！")
	var a_image = set_image_alpha(a, 1 - b_ratio) as Image
	var b_image = set_image_alpha(b, b_ratio) as Image
	a_image.blend_rect(
		b_image, 
		Rect2i(Vector2i(0,0), b_image.get_size()), 
		Vector2i(0,0)
	)
	return a_image


## Atlas 类型的贴图转为 Image
static func atlas_to_image(texture: AtlasTexture) -> Image:
	var p_t = texture.atlas as Texture2D
	return p_t.get_image().get_region( texture.region )


## 获取可用的大小范围的图片
static func get_used_rect_image(texture: Texture2D) -> Texture2D:
	var image = texture.get_image()
	if image:
		var rect = image.get_used_rect()
		var new_image = Image.create(rect.size.x, rect.size.y, image.has_mipmaps(), image.get_format())
		new_image.blit_rect(image, rect, Vector2i(0,0))
		return ImageTexture.create_from_image(new_image)
	return null


## 获取节点的 [Texture2D]
static func get_node_texture(node: CanvasItem) -> Texture2D:
	var texture : Texture2D 
	if node is AnimatedSprite2D:
		texture = TextureUtil.get_animated_sprite_current_frame(node)
	elif node is Sprite2D or node is TextureRect:
		texture = node.texture
	else:
		print("不是 [AnimatedSprite2D, Sprite2D, TextureRect] 中的类型！")
		return null
	return texture


##  重置大小
##[br]
##[br][code]texture[/code]  贴图
##[br][code]new_size[/code]  新的大小
##[br][code]interpolation[/code]  插值。影响图像的质量
##[br][code]return[/code]  返回新的 [Texture2D]
static func resize_texture(
	texture: Texture2D, 
	new_size: Vector2i
) -> Texture2D:
	var image = Image.new()
	image.copy_from(texture.get_image())
	image.resize(new_size.x, new_size.y, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(image)

