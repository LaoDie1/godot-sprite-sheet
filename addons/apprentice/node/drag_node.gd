#============================================================
#    Drag Node
#============================================================
# - author: zhangxuetu
# - datetime: 2023-03-19 15:31:09
# - version: 4.0
#============================================================
## 拖拽节点
class_name DragNode
extends Node2D


signal pressed(pos: Vector2, status: bool)
signal dragged(from: Vector2, to: Vector2)


var _pressed_pos : Vector2
var _last_released_pos : Vector2


func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_pressed_pos = get_global_mouse_position()
			else:
				_last_released_pos = get_global_mouse_position()
				self.dragged.emit(_pressed_pos, _last_released_pos)
			self.pressed.emit(_pressed_pos, event.pressed)

