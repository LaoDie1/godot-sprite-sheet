#============================================================
#    Anim Items
#============================================================
# - author: zhangxuetu
# - datetime: 2023-04-02 14:43:27
# - version: 4.0
#============================================================
extends HSplitContainer


signal played(animation: Animation)


@onready var anim_name_edit = %anim_name_edit
@onready var item_container = %item_container
@onready var frame_speed = %frame_speed
@onready var loop_btn = %loop_btn as BaseButton


var _texture_list: Array[Texture2D] = []


#============================================================
#  SetGet
#============================================================
## 获取动画
func get_animation() -> Animation:
	var animation = Animation.new()
	var textures = item_container.get_children().map(func(node): return node.texture )
	var interval = 1.0 / frame_speed.value
	animation.length = textures.size() * interval
	animation.loop_mode = Animation.LOOP_LINEAR if loop_btn.button_pressed else Animation.LOOP_NONE
	
	# 添加动画
	var track_key = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track_key, ".:texture")
	var texture : Texture2D
	for i in textures.size():
		animation.track_insert_key(track_key, interval * i, textures[i])
	return animation


## 获取精灵图片帧
func get_texture_list() -> Array[Texture2D]:
	return _texture_list

## 动画名
func get_animation_name() -> StringName:
	return anim_name_edit.text

func is_loop() -> bool:
	return loop_btn.button_pressed

func get_frame_speed() -> int:
	return frame_speed.value


#============================================================
#  自定义
#============================================================
func add_items(anim_name: String, texture_list: Array, show_size: Vector2) -> void:
	anim_name_edit.text = anim_name
	_texture_list = Array(texture_list, TYPE_OBJECT, "Texture2D", null)
	for texture in texture_list:
		var texture_rect = TextureRect.new()
		texture_rect.texture = texture
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture_rect.custom_minimum_size = show_size
		item_container.add_child(texture_rect)


#============================================================
#  连接信号
#============================================================
func _on_play_pressed():
	self.played.emit(get_animation())


func _on_remove_pressed():
	queue_free()
