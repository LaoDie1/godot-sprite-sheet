#============================================================
#    Priority Queue
#============================================================
# - datetime: 2022-11-23 12:32:19
#============================================================
## 优先队列
##
##会根据添加优先级进行排序
class_name PriorityQueue


#桶（使用桶排序设置优先级）
var _bucket := {}
#临时所有 item 列表，每次添加新的 item 时都会清空，如果为空，则会对桶内的元素进行排序，然后
#存放到这个列表中并返回结果
var _list := []
# 这个 Item 所在的优先级列表
var _priority : Dictionary = {}


## 获取队列中的所有项
func get_items() -> Array:
	if _list:
		return _list
	else:
		# 按优先级排序后获取其中的每个对象
		var keys = _bucket.keys()
		keys.sort()
		for id in keys:
			_list.append_array(_bucket[id])
	return _list


##  是否已经添加过这个 item 了
func has_item(item) -> bool:
	return _priority.has(item)


## 添加 item
func add_item(item, priority = 0):
	if not _bucket.has(priority):
		_bucket[priority] = []
	
	# 每次添加新的优先级顺序都会清空，在 get_items 时重新排序
	_list.clear()
	
	# 添加到这个优先级的列表中
	_bucket[priority].append(item)
	if _priority.has(item):
		_priority[item].append(priority)
	else:
		_priority[item] = []
		_priority[item].append(priority)


## 移除掉找到的这个 item
func remove_item(item) -> bool:
	if _priority.has(item):
		var list = _priority[item]
		for priority in list:
			_bucket[priority].erase(item)
		_priority.erase(item)
		return true
	return false

