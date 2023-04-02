#============================================================
#    F BT Distance Condition
#============================================================
# - datetime: 2022-09-14 14:46:59
#============================================================

##  从 [member from] 位置到 [member to] 位置距离的条件，通过设置 [member compare] 属性设置判断方式是大于、小于还是等于。
extends BaseConditionLeaf


## [member from] 到 [member to] 的距离进行比较
enum Compare {
	## 大于 [member distance] 时返回 SUCCEED
	GREATER,
	## 小于 [member distance] 时返回 SUCCEED
	LESS,
	## 等于 [member distance] 时返回 SUCCEED
	EQUAL,
}


##  比较方式，将 [member from] 的向量与 [member to] 向量的距离跟 [member distance] 作比较
@export
var compare : Compare = Compare.GREATER:
	set(v):
		compare = v
		if compare == Compare.GREATER:
			_condition = func(): 
				return bt_root.get_property(from).distance_squared_to( bt_root.get_property(to) ) > _squared_distance
		elif compare == Compare.LESS:
			_condition = func():
				return bt_root.get_property(from).distance_squared_to( bt_root.get_property(to) ) < _squared_distance
		else:
			_condition = func():
				return bt_root.get_property(from).distance_squared_to( bt_root.get_property(to) ) == _squared_distance
##  从这个位置开始移动（这个是黑板中的 key，需要先 bt_root.set_property 设置这个 key 的属性值才能使用）
@export
var from := ""
##  从这个位置开始移动（这个是黑板中的 key，需要先 bt_root.set_property 设置这个 key 的属性值才能使用）
@export
var to := ""
##  判断的距离
@export
var distance := 0.0 :
	set(v):
		distance = v
		_squared_distance = pow(distance, 2)


var _condition : Callable
var _squared_distance := 0.0


func _init() -> void:
	self.compare = compare
	self.distance = distance


#(override)
func _do():
	return _condition.call()



