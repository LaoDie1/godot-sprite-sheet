#============================================================
#    Canvas Util
#============================================================
# - author: zhangxuetu
# - datetime: 2023-03-12 18:05:05
# - version: 4.x
#============================================================
class_name CanvasUtil


## 让节点旋转到目标点
##[br]
##[br][code]node[/code]  设置旋转的目标
##[br][code]from[/code]  开始位置
##[br][code]to[/code]  旋转到位置
##[br][code]offset[/code]  旋转偏移位置
static func rotate_to(node: Node2D, from: Vector2, to: Vector2, offset: float = 0.0) -> void:
	node.global_rotation = to.angle_to_point(from) + offset


## 获取节点显示的图像的缩放大小
static func get_canvas_scale(node: CanvasItem) -> Vector2:
	return Vector2(get_canvas_size(node)) * node.scale


## 获取节点显示的图像的大小
static func get_canvas_size(node: CanvasItem) -> Vector2i:
	var texture := TextureUtil.get_node_texture(node) as Texture2D
	if texture:
		var image = texture.get_image() as Image
		return image.get_size()
	return Vector2i(0, 0)


## 获取两个节点的大小差异
static func get_canvas_scale_diff(node_a: Node2D, node_b: Node2D) -> Vector2:
	var scale_a = CanvasUtil.get_canvas_scale(node_a)
	var scale_b = CanvasUtil.get_canvas_scale(node_b)
	return scale_a / scale_b


##  根据 [AnimatedSprite2D] 当前的 frame 创建一个 [Sprite2D]
##[br]
##[br][code]animation_sprite[/code]  [AnimatedSprite2D] 类型的节点
##[br][code]return[/code]  返回一个 [Sprite2D] 节点
static func create_sprite_by_animated_sprite_current_frame(animation_sprite: AnimatedSprite2D) -> Sprite2D:
	var anim = animation_sprite.animation
	var idx = animation_sprite.frame
	var texture = animation_sprite.sprite_frames.get_frame_texture(anim, idx)  
	var sprite = Sprite2D.new()
	sprite.texture = texture
	sprite.global_position = animation_sprite.global_position
	sprite.offset = animation_sprite.offset
	return sprite


##  获取 [AnimatedSprite2D] 的动画的播放时长
static func get_animation_sprite_time(animated_sprite: AnimatedSprite2D, animations) -> float:
	if animations is String or animations is StringName:
		if animated_sprite:
			var count = animated_sprite.sprite_frames.get_frame_count(animations)
			var speed = 1.0 / animated_sprite.sprite_frames.get_animation_speed(animations)
			return speed * count / animated_sprite.speed_scale
	elif animations is Array:
		var time = 0.0
		for animation in animations:
			time += get_animation_sprite_time(animated_sprite, animation)
		return time
	else:
		assert(false, "不能是 String 和 Array 之外的类型")
	return 0.0

