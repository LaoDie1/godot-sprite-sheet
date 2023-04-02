#============================================================
#    Reverse
#============================================================
# - datetime: 2022-09-14 01:01:07
#============================================================
## 结果反转
@tool
class_name BTReverse
extends BaseDecorator


var result 


#(override)
func _task():
	result = get_child(0)._task()
	# 如果 成功，则返回 失败
	if result == SUCCEED:
		return FAILED
	# 如果 失败，则返回 成功
	elif result == FAILED:
		return SUCCEED
	
	else:
		return RUNNING
