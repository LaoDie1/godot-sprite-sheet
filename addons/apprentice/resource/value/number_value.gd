#============================================================
#    Number Value
#============================================================
# - author: zhangxuetu
# - datetime: 2023-03-25 19:33:45
# - version: 4.0
#============================================================
class_name NumberValue
extends ResValue


@export
var value : float = 0.0


#(override)
func get_value():
	return value


