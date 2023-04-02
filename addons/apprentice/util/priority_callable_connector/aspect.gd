#============================================================
#    Aspect
#============================================================
# - datetime: 2022-12-20 00:06:02
#============================================================
## 类似 Spring 切面
class_name Aspect


# 优先级范围
const DEFAULT_ASPECT_PRIORITY = 1000


## 在使用 around 方法连接的信号之前执行这个连接的方法
##[br]
##[br][code]_signal[/code]  连接的信号
##[br][code]callable[/code]  连接到的方法
##[br][code]priority[/code]  调用的优先级
static func before(_signal: Signal, callable: Callable, priority: int = 0):
	assert(priority < DEFAULT_ASPECT_PRIORITY, "priority 参数不能超过 " + str(DEFAULT_ASPECT_PRIORITY) + " 大小")
	return PriorityConnector.connect_signal(_signal, callable, PriorityConnector.DEFAULT_PRIORITY - DEFAULT_ASPECT_PRIORITY + priority)

## 使用默认的连接信号优先级执行
static func around(_signal: Signal, callable: Callable):
	return PriorityConnector.connect_signal(_signal, callable, PriorityConnector.DEFAULT_PRIORITY)

## 在使用 around 方法连接的信号之后执行这个连接的方法
static func after(_signal: Signal, callable: Callable, priority: int = 0):
	assert(priority > -DEFAULT_ASPECT_PRIORITY, "priority 参数不能小于 " + str(-DEFAULT_ASPECT_PRIORITY) + " 大小")
	return PriorityConnector.connect_signal(_signal, callable, PriorityConnector.DEFAULT_PRIORITY + DEFAULT_ASPECT_PRIORITY + priority)


## 连接具有优先级的信号
static func connect_signal(
	_signal: Signal, 
	callable: Callable, 
	priority: int = PriorityConnector.DEFAULT_PRIORITY
):
	return PriorityConnector.connect_signal(_signal, callable, priority)


## 断开连接
static func disconn(id) -> bool:
	return PriorityConnector.disconnect_id(id)


## 打断信号传播，不再执行之后的方法，一般用在 [method before] 连接的方法中
static func prevent_signal(_signal: Signal) -> void:
	PriorityConnector.prevent(_signal)


## 替换传播的信号的参数值
## params 参数要按照传入的参数进行排列
static func replace_params(_signal: Signal, params: Array) -> bool:
	return PriorityConnector.replace_params(_signal, params)

