#============================================================
#    Item Rect 2
#============================================================
# - author: zhangxuetu
# - datetime: 2023-04-05 12:44:16
# - version: 4.0
#============================================================
@tool
extends GridContainer


signal value_changed(value: Rect2i)


@export var x_name: String = "x":
	set(v):
		x_name = v
		%x_label.text = v
@export var y_name: String = "y":
	set(v):
		y_name = v
		%y_label.text = v
@export var w_name: String = "w":
	set(v):
		w_name = v
		%w_label.text = v
@export var h_name: String = "h":
	set(v):
		h_name = v
		%h_label.text = v
@export var editable : bool = true:
	set(v):
		editable = v
		_update_node_value("editable", v)
@export var value : Rect2:
	set(v):
		if value != v:
			value = v
			_update_value()
			%x.value = value.position.x
			%y.value = value.position.y
			%w.value = value.size.x
			%h.value = value.size.y
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
		_update_value()
		_update_node_value("min_value", v)
@export var max_value : float = 100.0:
	set(v): 
		max_value = v
		_update_value()
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

func get_value() -> Rect2:
	return Rect2(
		%x.value, %y.value,
		%w.value, %h.value
	)

func _update_node_value(prop: String, value):
	%x[prop] = value
	%y[prop] = value
	%w[prop] = value
	%h[prop] = value

func _update_value():
	if not allow_greater:
		value.position.x = min(value.position.x, max_value)
		value.position.y = min(value.position.y, max_value)
		value.size.x = min(value.size.x, max_value)
		value.size.x = min(value.size.y, max_value)
	if not allow_lesser:
		value.position.x = max(value.position.x, min_value)
		value.position.y = max(value.position.y, min_value)
		value.size.x = max(value.size.x, min_value)
		value.size.y = max(value.size.y, min_value)


#============================================================
#  内置
#============================================================
func _ready():
	var callback = func(v):
		self.value = Rect2i(%x.value, %y.value, %w.value, %h.value)
	%x.value_changed.connect(callback)
	%y.value_changed.connect(callback)
	%w.value_changed.connect(callback)
	%h.value_changed.connect(callback)


