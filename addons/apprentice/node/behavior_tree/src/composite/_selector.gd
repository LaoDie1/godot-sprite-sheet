#============================================================
#    Selector
#============================================================
# - datetime: 2022-09-14 00:59:21
#============================================================

## Selector 执行失败则继续执行，执行一次成功则返回成功
@tool
@icon("../../icon/FSelector.png")
class_name BTSelector
extends BaseComposite


var result = FAILED


#(override)
func _task():
	while task_idx < get_child_count():
		result = get_child(task_idx)._task()
		# 执行失败继续执行下一个，直到成功败或结束
		if result == FAILED:
			task_idx += 1
		else:
			break
	
	if task_idx >= get_child_count() || result == SUCCEED:
		task_idx = 0
		if result == SUCCEED:
			return SUCCEED
	
	# 如果都没有成功执行的，则回 FAILED
	return FAILED
