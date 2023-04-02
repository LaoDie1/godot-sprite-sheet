#============================================================
#    Float Text
#============================================================
# - author: zhangxuetu
# - datetime: 2023-03-16 22:27:38
# - version: 4.0
#============================================================
## 漂浮文字
class_name FloatText
extends Label



static func create(
	text: String, 
	position: Vector2, 
	scale : Vector2 = Vector2(1, 1), 
	font_size: int = 13,
	duration: float = 0.2
) -> FloatText:
	var label = FloatText.new()
	label.text = text
	label.scale = Vector2(0,0)
	label.add_theme_font_size_override("font_size", font_size)
	Engine.get_main_loop().current_scene.add_child(label)
	
	label.global_position = position - label.size / 2
	label.pivot_offset = label.size / 2
	label.create_tween() \
		.tween_property(label, "position:y", label.position.y - 5, duration) \
		.set_trans(Tween.TRANS_ELASTIC) \
		.set_ease(Tween.EASE_OUT)
	label.create_tween().tween_property(label, "scale", scale, 0.2) \
		.set_trans(Tween.TRANS_ELASTIC) \
		.set_ease(Tween.EASE_OUT) \
		.finished.connect(func():
			if is_instance_valid(label):
				await label.get_tree().create_timer(duration).timeout
				if is_instance_valid(label):
					label.create_tween().tween_property(label, "modulate:a", 0, 0.25).set_ease(Tween.EASE_OUT)
	)
	return label
