#============================================================
#    Parallel
#============================================================
# - datetime: 2022-09-14 01:00:04
#============================================================

## Paraller 并行节点，全部节点都执行一遍
@tool
@icon("../../icon/FParallel.png")
class_name BTParallel
extends BaseComposite


var result = SUCCEED
var have_failed = false

var last_task = 0


#(override)
func _task():
	have_failed = false
	
	# 运行全部子节点，有一个为失败，则返回 FAILED
	for task_idx in range(last_task, get_child_count()):
		var node = get_child(task_idx)
		result = get_child(task_idx)._task()
		if result == FAILED:
			have_failed = true
		elif result == RUNNING:
			return RUNNING
	
	last_task = 0
	## 如果有运行失败的节点，则返回 FAILED
	if have_failed:
		return FAILED
	# 如果全部都是成功状态，则返回 SUCCEE
	else:
		return SUCCEED

