#============================================================
#    Animation Panel
#============================================================
# - author: zhangxuetu
# - datetime: 2023-04-02 14:39:14
# - version: 4.0
#============================================================
@tool
class_name GenerateSpriteSheet_AnimationPanel
extends MarginContainer


## 开始播放动画
signal played(animation: Animation)
## 停止播放动画
signal stopped
## 已经导出动画资源容器，用于 [AnimationPlayer] 中
signal exported_animation_library(animation_library: AnimationLibrary)
## 已经导出精灵动画帧，用于 [AnimatedSprite2D] 中
signal exported_sprite_frames(sprite_frames: SpriteFrames)
## 添加这个动画序列到待处理区
signal added_to_pending(texture_list: Array[Texture2D])


const ANIM_ITEMS_SCENE = preload("anim_items.tscn")
const ANIM_ITEMS_SCRIPT = preload("anim_items.gd")


@onready var anim_item_container = %anim_item_container
@onready var prompt_label = %prompt_label
@onready var export_res_dialog := %export_res_dialog as FileDialog
@onready var scroll_container = %ScrollContainer


var _last_export_type : String = ""


#============================================================
#  SetGet
#============================================================
func has_animation_items() -> bool:
	return anim_item_container.get_child_count() > 0


#============================================================
#  内置
#============================================================
func _can_drop_data(at_position, data):
	return (
		data is Dictionary
		and data.has("type")
		and data['type'] == "texture_data_list"	# 这个值在 pending 下的 item 中
	)


func _drop_data(at_position, data):
	# 放下数据，添加动画组
	var callback_data_list : Array[Dictionary] = data['data']
	# 添加动画组
	var texture_list = Array(
		callback_data_list.map(func(data): return data['texture']),
		TYPE_OBJECT, "Texture2D", null
	)
	add_animation_items(texture_list)
	
	prompt_label.visible = false
	
	# 取消选中状态
	for callback_data in callback_data_list:
		var node = callback_data['node']
		node.set_selected(false)


#============================================================
#  自定义
#============================================================
## 添加动画组
func add_animation_items(texture_list: Array[Texture2D]):
	var items = ANIM_ITEMS_SCENE.instantiate()
	anim_item_container.add_child(items)
	items.add_items("anim_%s" % items.get_index(), texture_list, Vector2(32, 32))
	items.played.connect(func(animation): self.played.emit(animation) )
	items.added_to_pending.connect(func(): self.added_to_pending.emit(texture_list) )
	scroll_container.scroll_vertical += items.size.y


## 生成动画资源容器，用于 [AnimationPlayer] 中
func generate_animation_library() -> AnimationLibrary:
	var anim_lib = AnimationLibrary.new()
	for child in anim_item_container.get_children():
		child = child as ANIM_ITEMS_SCRIPT
		if child is ANIM_ITEMS_SCRIPT:
			var animation: Animation = child.get_animation()
			var anim_name: String = child.get_animation_name()
			anim_lib.add_animation(anim_name, animation)
	return anim_lib


## 生成精灵动画帧，用于 [AnimatedSprite2D] 中
func generate_sprite_frames() -> SpriteFrames:
	var sprite_frames := SpriteFrames.new()
	for child in anim_item_container.get_children():
		child = child as ANIM_ITEMS_SCRIPT
		if child is ANIM_ITEMS_SCRIPT:
			var texture_list : Array[Texture2D] = child.get_texture_list()
			# 添加动画
			var anim_name: String = child.get_animation_name()
			var idx = 0
			while sprite_frames.has_animation(anim_name):
				idx += 1
				anim_name = "anim_%s" % idx
			sprite_frames.add_animation(anim_name)
			# 追加动画帧
			var loop = child.is_loop()
			var frame_speed = child.get_frame_speed()
			sprite_frames.set_animation_speed(anim_name, frame_speed)
			sprite_frames.set_animation_loop(anim_name, loop)
			for texture in texture_list:
				sprite_frames.add_frame(anim_name, texture)
	return sprite_frames


#============================================================
#  连接信号
#============================================================
func _on_stop_anim_pressed():
	self.stopped.emit()


func _on_export_as_animation_pressed():
	if not has_animation_items():
		GenerateSpriteSheetMain.show_message("没有添加动画")
		return 
	
	_last_export_type = "AnimationLibrary"
	export_res_dialog.popup_centered()


func _on_export_as_sprite_frames_pressed():
	if not has_animation_items():
		GenerateSpriteSheetMain.show_message("没有添加动画")
		return 
	
	# 导出精灵动画帧，用于 [AnimatedSprite2D] 中
	_last_export_type = "SpriteFrames"
	export_res_dialog.popup_centered()


func _on_export_res_dialog_file_selected(path):
	# 保存文件
	if _last_export_type == "AnimationLibrary":
		var res = generate_animation_library()
		ResourceSaver.save(res, path)
		exported_animation_library.emit(res)
		GenerateSpriteSheetMain.show_message("已导出为 AnimationLibrary 文件")
		
	elif _last_export_type == "SpriteFrames":
		var res = generate_sprite_frames()
		ResourceSaver.save(res, path)
		self.exported_sprite_frames.emit(res)
		GenerateSpriteSheetMain.show_message("已导出为 SpriteFrames 文件")
	
	else:
		GenerateSpriteSheetMain.show_message("错误的导出类型，程序出现BUG")

