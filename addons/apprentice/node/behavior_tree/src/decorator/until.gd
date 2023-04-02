#============================================================
#    Until
#============================================================
# - datetime: 2022-09-14 23:56:46
#============================================================
## 直到返回 [member match_result] 结果之前都返回 RUNNING
@tool
@icon("../../icon/FUntil.png")
class_name BTUntil
extends BaseDecorator


## 匹配的结果，返回这个结果则返回 SUCCEED，否则其他情况都返回 RUNNING
@export_enum("Success", "Fail", "Running")
var match_result : int = 0


var result


#(override)
func _task():
	result = get_child(0)._task()
	if result == match_result:
		return SUCCEED
	return RUNNING

