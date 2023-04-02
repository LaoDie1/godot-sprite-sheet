#============================================================
#    Action
#============================================================
# - datetime: 2022-09-14 01:03:04
#============================================================

##  行为节点。在 [method _do] 方法中重写功能。
@icon("../../icon/FAction.png")
class_name BaseActionLeaf
extends BaseLeaf


var _result


#(override)
func _task():
	_result = _do()
	if _result:
		return _result
	return SUCCEED


##  重写方法以执行功能
func _do():
	pass



