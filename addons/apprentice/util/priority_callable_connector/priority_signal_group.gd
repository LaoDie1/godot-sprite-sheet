#============================================================
#    Priority Signal Group
#============================================================
# - author: zhangxuetu
# - datetime: 2023-03-15 19:03:07
# - version: 4.0
#============================================================
class_name PrioritySignalGroup


# 优先级队列
var _queue : PriorityQueue = PriorityQueue.new()
# 已添加的 Callable， key 为 Callable
var _added : Dictionary = {}
# ID 对应的Callable
var _id_to_callable : Dictionary = {}


# 当前执行时的 ID
var _execute_id : int = 0
# 打断的的 ID
var _prevent : Dictionary = {}
# 用于执行方法时的传参
var _params : Dictionary = {}


##  添加回调
##[br]
##[br][code]callable[/code]  回调方法
##[br][code]priority[/code]  优先级的值
##[br][code]return[/code]  返回这个连接的 ID
func add_callable(callable: Callable, priority: int = 0) -> String:
	if _added.has(callable):
		printerr("已经添加过这个回调！")
		return ""
	_queue.add_item(callable, priority)
	
	var id = DataUtil.generate_id([callable])
	_id_to_callable[id] = callable
	return id


##  移除ITEM
##[br]
##[br][code]id[/code]  
##[br][code]return[/code]  
func remove_item(id) -> bool:
	var callable = _id_to_callable.get(id)
	if callable:
		_added.erase(callable)
		return _queue.remove_item(callable)
	return false


##  执行调用所有 Callable
##[br]
##[br][code]params[/code]  传入参数
func execute(params: Array) -> void:
	# 递增
	_execute_id += 1
	if _execute_id == 0x7FFFFFFFFFFFFFFF:
		_execute_id = 0
		_prevent.clear()
	
	# 执行
	var id = _execute_id
	_params[id] = params
	for callable in _queue.get_items():
		if _prevent.has(id):
			_prevent.erase(id)
			break
		callable.callv(_params[id])
	_params.erase(id)


## 阻断执行，后面的及优先级靠后的方法将不再执行
func prevent() -> void:
	_prevent[_execute_id] = null


## 替换掉参数。（用在执行时优先级较高的地方进行后面低优先级参数的改变，不适合在 await 之后使用）
##[br]
##[br][code]params[/code]  替换的参数。数量需要与信号数量相同
func replace_param(params: Array) -> bool:
	if _params.has(_execute_id):
		assert(len(_params[_execute_id]) == len(params), "参数数量必须保持一致" )
		_params[_execute_id] = params
		return true
	return false


