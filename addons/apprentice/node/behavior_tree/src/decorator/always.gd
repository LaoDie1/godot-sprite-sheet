#============================================================
#    Always
#============================================================
# - datetime: 2022-09-14 23:55:23
#============================================================
##  总是返回这个执行结果
@tool
@icon("../../icon/FAlways.png")
class_name BTAlways
extends BaseDecorator


##  总是返回这个结果
@export_enum("Success", "Fail", "Running")
var return_result : int = 0


#(override)
func _task():
	get_child(0)._task()
	return return_result

