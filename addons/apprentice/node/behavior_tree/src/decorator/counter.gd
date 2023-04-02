#============================================================
#    Counter
#============================================================
# - datetime: 2022-09-14 22:46:04
#============================================================
##  执行结果达到数量之前则会一直返回 RUNNING，如果执行失败，则返回 FAILED
@tool
class_name BTCounter
extends BaseDecorator


@export_range(0, 1, 1, "or_greater")
var count_max : int = 1


var result
var count := 0


#(override)
func _task():
	if count_max == 0:
		return FAILED
	result = get_child(0)._task()
	if result == SUCCEED:
		count += 1
		if count >= count_max:
			count = 0
			return SUCCEED
	elif result == FAILED:
		count = 0
		return FAILED
	
	return RUNNING



