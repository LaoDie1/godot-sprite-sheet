#============================================================
#    Priority Connector
#============================================================
# - author: zhangxuetu
# - datetime: 2023-03-15 20:05:12
# - version: 4.0
#============================================================
##优先级回调连接器
##
##[br]使 callable 带有有优先级，使调用的 [Callable] 拥有先后顺序。默认优先级值为 [member DEFAULT_PRIORITY]
##[br]
##[br]示例，连接一个信号到一个方法上：
##[codeblock]
##PriorityConnector.connect_signal(Object.signal, Object.method_01, 5)
##PriorityConnector.connect_signal(Object.signal, Object.method_02, 4)
##[/codeblock]
##[br]上例代码调用 [code]Object.signal[/code] 信号时，将会先调用优先级低的方法，也就是先调用 [code]Object.method_02[/code]
##的方法，然后调用 [code]Object.method_01[/code] 方法，这样可以防止因为连接顺序或其他原因导
##致连接调用方法的先后顺序错误
class_name PriorityConnector


const DEFAULT_PRIORITY = 0


static func _instance(_signal: Signal) -> PrioritySignalGroup:
	var data = DataUtil.get_meta_dict_data("PriorityConnector_instance")
	return DataUtil.get_value_or_set(data, _signal, func():
		var group = PrioritySignalGroup.new()
		SignalUtil.connect_array_arg_callable(_signal, group.execute)
		return group
	)

static func _id_to_signal_map() -> Dictionary:
	return DataUtil.get_meta_dict_data("PriorityConnector_id_to_signal_map")


static func connect_signal(_signal: Signal, callable: Callable, priority: int = DEFAULT_PRIORITY) -> String:
	var group = _instance(_signal)
	var id = group.add_callable(callable, priority)
	ErrorLog.is_true(id == "", "已经连接过了")
	_id_to_signal_map()[id] = _signal
	return id


static func disconnect_id(id) -> bool:
	var _signal = _id_to_signal_map().get(id)
	if _signal:
		var group = _instance(_signal)
		group.remove_item(id)
		return true
	return false


static func prevent(_signal: Signal) -> void:
	var group = _instance(_signal)
	group.prevent()


static func replace_params(_signal: Signal, params: Array) -> bool:
	var group = _instance(_signal)
	return group.replace_param(params)

