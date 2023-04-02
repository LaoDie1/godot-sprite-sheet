#============================================================
#    Priority Callable Connector
#============================================================
# - datetime: 2022-11-23 12:49:58
#============================================================
##优先级回调连接器
##
##[br]使 callable 带有有优先级，使调用的 [Callable] 拥有先后顺序。默认优先级值为 [member DEFAULT_PRIORITY]
##[br]
##[br]示例，连接一个信号到一个方法上：
##[codeblock]
##PriorityCallableConnector.connect_signal(Object.signal, Object.method_01, 5)
##PriorityCallableConnector.connect_signal(Object.signal, Object.method_02, 4)
##[/codeblock]
##[br]上例代码调用 [code]Object.signal[/code] 信号时，将会先调用优先级低的方法，也就是先调用 [code]Object.method_02[/code]
##的方法，然后调用 [code]Object.method_01[/code] 方法，这样可以防止因为连接顺序或其他原因导
##致连接调用方法的先后顺序错误
##[br]
##[br]如果你不是连接信号，而只是命名一个组：
##[codeblock]
##var priority_connector = PriorityCallableConnector.instance(self)
##priority_connector.add_callable(GroupName, Object.method, 5)
##priority_connector.add_callable(GroupName, Object.method, 1)
##[/codeblock]
##[br]调用这个组时，通过 [method instance] 方法获取那个对象的实例，然后调用 [method PriorityGroup.call_group]
##方法
##[codeblock]
##PriorityCallableConnector.instance(Object).call_group(GroupName, [param01, ...])
##[/codeblock]
class_name PriorityCallableConnector


## 默认优先级值
const DEFAULT_PRIORITY : int = 0


# 当前对应 id 的优先级队列
static func get_priority_callable_queue_data():
	return DataUtil.get_meta_data("get_priority_callable_queue_data", func(): return {})

# 对应的方法调用的代理回调方法
static func get_agent_callable():
	return DataUtil.get_meta_data("get_agent_callable", func(): return {})



#============================================================
#  自定义
#============================================================
##  实例化这个对象的连接器
##[br]
##[br][code]id[/code]  这个 ID 的 [PriorityGroup] 对象，防止重复创建。这个
##ID可以是任何类型的值：[int]、[float]、[String]、[Object]、[Signal]、[Callable]等
##[br]
##[br][code]return[/code]  返回这个优先级队列连接器
static func instance(id) -> PriorityGroup:
	if get_priority_callable_queue_data().has(id):
		return get_priority_callable_queue_data()[id] as PriorityGroup
	else:
		get_priority_callable_queue_data()[id] = PriorityGroup.new()
		return get_priority_callable_queue_data()[id] as PriorityGroup


#static func is_connected_signal(_signal: Signal, callable: Callable):
#	var connector = instance(_signal)
	


## 连接这个信号到这个回调。这个方法默认会调用 [method PriorityGroup.add_callable] 方法，将这个
##方法添加到以 _signal 参数值为 ID 的组中，信号连接到这个代理的 [Callable] 调用这些方法
##[br]
##[br][code]_signal[/code]  连接的信号
##[br][code]callable[/code]  连接的方法
##[br][code]priority[/code]  调用这个方法时的优先级
static func connect_signal(_signal: Signal, callable: Callable, priority: int = DEFAULT_PRIORITY):
	
#	Log.info([ "[ 连接 ]", _signal, "到", callable.get_object(), "的", callable, "方法" ])
	
	# 将 callable 添加到这个信号组
	var connector = instance(_signal)
	var id = connector.add_callable(_signal, callable, priority)
	if id == null:
		printerr(_signal.get_name(), " 信号已连接过 ", callable, " 方法")
		return
	
	# 没有连接的代理方法时，开始进行创建并连接
	if not get_agent_callable().has(_signal):
		
		# 信号调用的时候调用这个组中的 Callable
		var signal_name = _signal.get_name()
		var object : Object = _signal.get_object() as Object
		var agent_method : Callable
		
		# 遍历查找这个信号的数据。不根据 Callable 查找参数数量的原因是因为 Callable 可能是一
		# 个匿名方法，没有对象
		for data in object.get_signal_list():
			if data['name'] == signal_name:
				# 根据信号的参数数量，创建代理方法
				var args_count = data['args'].size()
				match args_count:
					0:
						agent_method = func():
							connector.call_group(_signal, [])
					1:
						agent_method = func(arg0):
							connector.call_group(_signal, [arg0])
					2:
						agent_method = func(arg0, arg1):
							connector.call_group(_signal, [arg0, arg1])
					3:
						agent_method = func(arg0, arg1, arg2):
							connector.call_group(_signal, [arg0, arg1, arg2])
					4:
						agent_method = func(arg0, arg1, arg2, arg3):
							connector.call_group(_signal, [arg0, arg1, arg2, arg3])
					5:
						agent_method = func(arg0, arg1, arg2, arg3, arg4):
							connector.call_group(_signal, [arg0, arg1, arg2, arg3, arg4])
					6:
						agent_method = func(arg0, arg1, arg2, arg3, arg4, arg5):
							connector.call_group(_signal, [arg0, arg1, arg2, arg3, arg4, arg5])
					7:
						agent_method = func(arg0, arg1, arg2, arg3, arg4, arg5, arg6):
							connector.call_group(_signal, [arg0, arg1, arg2, arg3, arg4, arg5, arg6])
					8:
						agent_method = func(arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7):
							connector.call_group(_signal, [arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7])
					9:
						agent_method = func(arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8):
							connector.call_group(_signal, [arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8])
					10:
						agent_method = func(arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9):
							connector.call_group(_signal, [arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9])
				
				break
		
		_signal.connect(agent_method)
		# 记录这个信号的代理回调
		get_agent_callable()[_signal] = agent_method
	
	return id


## 阻断信号继续传播执行连接的方法
static func prevent_signal(_signal: Signal):
	instance(_signal).prevent(_signal)


## 替换掉参数。（用在执行时优先级较高的地方进行后面低优先级参数的改变，不适合在 await 之后使用）
##[br]
##[br][code]_signal[/code]  替换的信号的数据
##[br][code]params[/code]  替换的参数。数量需要与信号数量相同
static func replace_params(_signal: Signal, params: Array):
	instance(_signal).replace_params(_signal, params)
