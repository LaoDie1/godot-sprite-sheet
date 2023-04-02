#============================================================
#    Decorator
#============================================================
# - datetime: 2022-09-14 23:34:32
#============================================================
##  装饰节点
@tool
@icon("../../icon/FDecorator.png")
class_name BaseDecorator
extends BaseBTNode



func _get_configuration_warnings():
	var list = PackedStringArray()
	if not (get_parent() is BaseBTNode
		or get_parent() is BTRoot
	):
		list.append("没有父行为树节点")
	if get_child_count() == 0:
		list.append("没有添加子行为树节点，执行到这个节点时会报错")
	elif get_child_count() > 1:
		list.append("超出了 1 个节点，只有第一个节点会被执行")
	return list

