#============================================================
#    Min Max Value
#============================================================
# - author: zhangxuetu
# - datetime: 2023-03-12 22:54:30
# - version: 4.x
#============================================================
class_name RandomValue
extends NumberValue


@export
var max_value : float = 0.0


func get_value() -> float:
	return randf_range(value, max_value)
