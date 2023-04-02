#============================================================
#    Condition
#============================================================
# - datetime: 2022-09-14 01:02:39
#============================================================

##  条件节点
@icon("../../icon/FCondition.png")
class_name BaseConditionLeaf
extends BaseLeaf



#(override)
func _task():
	return SUCCEED if _do() else FAILED


##  重写以执行功能
func _do() -> bool:
	return true

