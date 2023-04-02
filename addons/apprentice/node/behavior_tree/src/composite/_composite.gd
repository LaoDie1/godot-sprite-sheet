#============================================================
#    Composite
#============================================================
# - datetime: 2022-10-03 17:07:00
#============================================================
## 组合节点
@tool
class_name BaseComposite
extends BaseBTNode



func _get_configuration_warnings() -> PackedStringArray:
	if get_child_count() == 0:
		return ["没有子为树节点"]
	
	return []

