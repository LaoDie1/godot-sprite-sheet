#============================================================
#    Behavior Tree Base
#============================================================
# - datetime: 2022-09-14 00:56:51
#============================================================

## BTNode 行为树的基类节点
@icon("../icon/FNodeBase.png")
class_name BaseBTNode
extends Node


## 任务执行结果
enum {
	SUCCEED,		# 执行成功
	FAILED,			# 执行败
	RUNNING,		# 正在执行
}


# 当前执行的 task 的 index（执行的第几个节点）
var task_idx : int = 0


## 节点的任务，返回执行结果
func _task() -> int:
	return SUCCEED

