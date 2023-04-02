#============================================================
#    Border
#============================================================
# - datetime: 2023-01-31 19:52:52
#============================================================
## 鼠标经过后显示边框
@tool
class_name ControlHoverBorder
extends ReferenceRect


@export
var target : Control


func _init():
	if Engine.is_editor_hint():
		self.editor_only = false
		self.mouse_filter = Control.MOUSE_FILTER_IGNORE
		self.visible = false


func _ready():
	if target:
		target.mouse_entered.connect( func(): self.visible = true )
		target.mouse_exited.connect( func(): self.visible = false )
	
