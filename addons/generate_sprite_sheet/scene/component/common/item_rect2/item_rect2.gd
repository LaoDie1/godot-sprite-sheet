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
		%x.editable = v
		%y.editable = v
		%w.editable = v
		%h.editable = v
@export var value : Rect2:
	set(v):
		if value != v:
			value = v
			%x.value = value.position.x
			%y.value = value.position.y
			%w.value = value.size.x
			%h.value = value.size.y
			self.value_changed.emit(value)
@export var step : float = 1.0:
	set(v):
		step = v
		%x.step = step
		%y.step = step
		%w.step = step
		%h.step = step
@export var suffix : String = "px":
	set(v):
		suffix = v
		%x.suffix = suffix
		%y.suffix = suffix
		%w.suffix = suffix
		%h.suffix = suffix


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


