#============================================================
#    Item Vector 2
#============================================================
# - author: zhangxuetu
# - datetime: 2023-04-05 12:38:33
# - version: 4.0
#============================================================
@tool
extends BoxContainer


signal value_changed(value: Vector2)


@export var x_name : String = "x":
	set(v):
		x_name = v
		%x_label.text = v
@export var y_name : String = "y":
	set(v):
		y_name = v
		%y_label.text = v
@export var editable : bool = true:
	set(v):
		editable = v
		%x.editable = v
		%y.editable = v
@export var value : Vector2:
	set(v):
		if value != v:
			value = v
			%x.value = value.x
			%y.value = value.y
			self.value_changed.emit(value)
@export var step : float = 1.0:
	set(v):
		step = v
		%x.step = step
		%y.step = step
@export var suffix : String = "px":
	set(v):
		suffix = v
		%x.suffix = suffix
		%y.suffix = suffix


#============================================================
#  SetGet
#============================================================
func get_item_node(item_type: String):
	return get_node("%" + item_type)


func get_value() -> Vector2:
	return Vector2( %x.value, %y.value )



#============================================================
#  内置
#============================================================
func _ready():
	var callback = func(v):
		self.value = Vector2(%x.value, %y.value)
	%x.value_changed.connect(callback)
	%y.value_changed.connect(callback)


