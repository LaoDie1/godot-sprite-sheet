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
		_update_node_value("editable", v)
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
		_update_node_value("step", v)
@export var suffix : String = "px":
	set(v):
		suffix = v
		_update_node_value("suffix", v)
@export var min_value : float = 0.0:
	set(v): 
		min_value = v
		if not allow_lesser:
			value.x = max(value.x, min_value)
			value.y = max(value.y, min_value)
		_update_node_value("min_value", v)
@export var max_value : float = 100.0:
	set(v): 
		max_value = v
		if not allow_greater:
			value.x = min(value.x, max_value)
			value.y = min(value.y, max_value)
		_update_node_value("max_value", v)
@export var allow_greater : bool = false:
	set(v):
		allow_greater = v
		_update_node_value("allow_greater", v)
@export var allow_lesser : bool = false:
	set(v):
		allow_lesser = v
		_update_node_value("allow_lesser", v)


#============================================================
#  SetGet
#============================================================
func get_item_node(item_type: String):
	return get_node("%" + item_type)


func get_value() -> Vector2:
	return Vector2( %x.value, %y.value )


func _update_node_value(prop, value):
	%x[prop] = value
	%y[prop] = value


#============================================================
#  内置
#============================================================
func _ready():
	var callback = func(v):
		self.value = Vector2(%x.value, %y.value)
	%x.value_changed.connect(callback)
	%y.value_changed.connect(callback)


