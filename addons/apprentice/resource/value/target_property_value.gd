#============================================================
#    Target Property Value
#============================================================
# - author: zhangxuetu
# - datetime: 2023-03-15 13:06:22
# - version: 4.0
#============================================================
## 目标属性值
class_name TargetPropertyValue
extends ResValue


@export
var target : Node
@export
var property : String = ""


func get_value():
	assert(property != "", "属性名不能为空")
	if property in target:
		return null
	return target[property]
