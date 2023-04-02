#============================================================
#	Move To Path
#============================================================
# @datetime: 2022-8-1 22:04:46
#============================================================

class_name MoveToPath
extends Node2D


signal moved_next(pos)
signal move_finish
signal stopped


var _starting : bool = false
var _pos_list : Array = []


#============================================================
#   SetGet
#===========================================================
func get_pos_list() -> Array:
	return _pos_list


#============================================================
#   自定义
#============================================================
# 移动到下一个位置
func next():
	if _starting:
		if _pos_list.size() > 1:
			# 移动到点路径位置
			emit_signal("moved_next", _pos_list.pop_back())
		else:
			_starting = false
			emit_signal("move_finish")


##  移动到位置
func to(position_list: Array):
	_starting = true
	# 翻转一下 next() 移除位置时从末尾移除，这样消耗最小
	position_list.reverse()
	_pos_list = position_list
	next()


##  停止
func stop():
	if _starting:
		_pos_list = []
		_starting = false
		emit_signal("stopped")


