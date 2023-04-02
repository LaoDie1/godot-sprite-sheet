#============================================================
#    Event
#============================================================
# - author: zhangxuetu
# - datetime: 2023-03-20 23:43:30
# - version: 4.0
#============================================================
## 事件
##
## 与信号同的是，这个是作为全局进行连接调用，且ID可以是任意值
##[br]示例
##[codeblock]
##var id = Event.listen("enter_room", func(data: Dictionary):
##    print("进入了房间！ data = ", data)
##)
##[/codeblock]
##[br]取消监听
##[codeblock]
##Event.cancel("enter_room", id)
##[/codeblock]
class_name Event



static func _get_data() -> Dictionary:
	return DataUtil.get_meta_dict_data("Event_get_data_dict")


## 监听一个组
##[br]
##[br][code]group[/code]  监听的组
##[br][code]callable[/code]  这个组的回调，这个方法需要有一个 [Dictionary] 类型的参数接收数据
##[br][code]return[/code]  返回连接的回调。可以当做组别 进行记录
static func listen(group, callable: Callable) -> Callable:
	var list : Array[Callable] = DataUtil.get_value_or_set(_get_data(), group, func(): 
		return Array([], TYPE_CALLABLE, "Callable", null) 
	)
	list.append(callable)
	return callable


##  发送一个消息
##[br]
##[br][code]group[/code] 发送到的组
##[br][code]data[/code]  发送的数据
static func send(group, data: Dictionary) -> void:
	var list : Array[Callable] = DataUtil.get_value_or_set(_get_data(), group, func(): 
		return Array([], TYPE_CALLABLE, "Callable", null) 
	)
	for callable in list:
		callable.call(data)


##  取消监听
##[br]
##[br][code]group[/code]  监听的组
##[br][code]callable[/code]  取消的回调
static func cancel(group, callable: Callable) -> void:
	var list : Array[Callable] = DataUtil.get_value_or_set(_get_data(), group, func(): 
		return Array([], TYPE_CALLABLE, "Callable", null) 
	)
	list.erase(callable)

