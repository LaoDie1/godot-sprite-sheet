#============================================================
#    Signal Util
#============================================================
# - datetime: 2023-02-09 14:09:01
#============================================================
## 信号工具
class_name SignalUtil


const NO_ARG_METHOD = """extends RefCounted
# 参数
var {CALLABLE}: Callable
func {METHOD}({from_arg}):
	{CALLABLE}.call()
"""


const SIGANAL_CONN_SIGNAL = """extends RefCounted
# 参数
var {SIGNAL}: Signal
func {METHOD}({from_args}):
	{SIGNAL}.emit({to_args})
"""

const SIGNAL_CONN_CALLV = """extends RefCounted
# 参数
var {CALLABLE}: Callable
func {METHOD}({from_arg}):
	{CALLABLE}.call([{from_arg}])
"""


const SIGNAL = "SIGNAL"
const METHOD = "METHOD"
const CALLABLE = "CALLABLE"


#============================================================
#  代理脚本
#============================================================
class ProxyScript:
	
	# 生成参数列表字符串
	static func _arg_list(arg_count: int) -> String:
		return ", ".join( range(arg_count).map( func(i): return "arg" + str(i) ) )
	
	## 创建代理脚本
	##[br]from_arg_num: 信号参数数量
	##[br]to_arg_num: 要连接到的参数的数量
	static func create_emit_script(
		from_arg_num: int, 
		to_arg_num: int
	) -> GDScript:
		var count_map : Dictionary = DataUtil.get_meta_dict_data("SignalUtil_ProxyScript_create_emit_script")
		var arg_num_key = ", ".join([from_arg_num, to_arg_num])
		return DataUtil.get_value_or_set(count_map, arg_num_key, func():
			Log.info(["创建 ", arg_num_key, " 个参数的代理脚本"])
			var script = GDScript.new()
			script.source_code = SIGANAL_CONN_SIGNAL.format({
				# 连接的信号的参数数量
				"from_args": _arg_list(from_arg_num),
				"to_args": _arg_list(to_arg_num),
				"SIGNAL": SIGNAL,
				"METHOD": METHOD,
			})
			script.reload()
			return script
		)
	
	## 连接调用无参数的脚本
	static func create_no_arg_script(from_signal_arg_num: int) -> GDScript:
		var map_data : Dictionary = DataUtil.get_meta_dict_data("SignalUtil_ProxyScript_create_no_arg_script")
		return DataUtil.get_value_or_set(map_data, from_signal_arg_num, func():
			var script = GDScript.new()
			script.source_code = NO_ARG_METHOD.format({
				"METHOD": METHOD,
				"CALLABLE": CALLABLE,
				"from_arg": _arg_list(from_signal_arg_num),
			})
			script.reload()
			return script
		)
	
	## 创建调用回调的 callv 方法的代理执行对象
	static func create_array_param_script(from_signal_arg_num: int) -> GDScript:
		var map_data : Dictionary = DataUtil.get_meta_dict_data("SignalUtil_ProxyScript_create_v_callable_script")
		return DataUtil.get_value_or_set(map_data, from_signal_arg_num, func():
			var script = GDScript.new()
			var code = SIGNAL_CONN_CALLV.format({
				"METHOD": METHOD,
				"CALLABLE": CALLABLE,
				"from_arg": _arg_list(from_signal_arg_num),
			})
			script.source_code = code
			script.reload()
			return script
		)
	


#============================================================
#  自定义
#============================================================
## 获取信号参数的数量
static func get_argument_num(_signal: Signal) -> int:
	var data : Dictionary = DataUtil.get_meta_dict_data("SignalUtil_get_argument_num")
	return DataUtil.get_value_or_set(data, _signal, func():
		# 获取这个信号的参数数量
		var signal_name = _signal.get_name()
		var object = _signal.get_object()
		for d in object.get_signal_list():
			if d['name'] == signal_name:
				var arg_num = d["args"].size()
				data[_signal] = arg_num
				return arg_num
		return 0
	)


##  根据信号生成去调用没有参数的方法
##[br]
##[br][code]_signal[/code]  根据信号参数数量生成对应参数个数的方法
##[br][code]callback[/code]  连接的没有参数的方法
##[br][code]object[/code]  代理对象的生命依赖对象
static func get_method_by_sginal_call_no_arg(_signal: Signal, callback: Callable, object: Object = null):
	var arg_num = get_argument_num(_signal)
	var script = ProxyScript.create_no_arg_script(arg_num)
	var proxy = script.new() as Object
	proxy[CALLABLE] = callback
	if object == null:
		object = _signal.get_object()
	var method = proxy[METHOD]
	ObjectUtil.ref_target(proxy, object)
	return method


##  连接没有参数的方法。不理会信号有多少参数，直接连接到方法，这个方法也不能有参数
##[br]
##[br][code]_signal[/code]  信号
##[br][code]callback[/code]  连接的方法
##[br][code]object[/code]  代理对象的生命依赖对象
static func connect_no_arg_method(_signal: Signal, callback: Callable, object: Object = null) -> Callable:
	var callable = get_method_by_sginal_call_no_arg(_signal, callback, object)
	_signal.connect(callable)
	return callable


##  连接信号。两个信号参数数量要保持一致
##[br]
##[br][code]from_signal[/code]  信号
##[br][code]to_signal[/code]  要连接到的信号
static func connect_signal(from_signal: Signal, to_signal: Signal) -> Callable:
	var from_arg_num = get_argument_num(from_signal)
	var to_arg_num = get_argument_num(to_signal)
	var script = ProxyScript.create_emit_script(from_arg_num, to_arg_num)
	
	# 设置调用信号代理对象
	var proxy = script.new() as Object
	# 设置调用的信号
	proxy[SIGNAL] = to_signal
	# 连接个方法
	var to_callable = proxy[METHOD]
	from_signal.connect( to_callable )
	
	# 设置对象引用，防止当前方法结束后代理对象消失
	var from_signal_object : Object = from_signal.get_object() as Object
	ObjectUtil.ref_target(proxy, from_signal_object)
	return to_callable


##  连接到这个方法，参数转为数组作为单个参数调用方法。
##[br]
##[br][code]from_signal[/code]  连接的信号
##[br][code]callable[/code]  信号连接到的方法回调，这个方法需要有个 [Array] 参数接收信号的参数列表
static func connect_array_arg_callable(from_signal: Signal, callable: Callable) -> Callable:
	var from_arg_num = get_argument_num(from_signal)
	var script = ProxyScript.create_array_param_script(from_arg_num)
	
	var proxy = script.new() as Object
	proxy[CALLABLE] = callable
	from_signal.connect(proxy[METHOD])
	
	var from_signal_object : Object = from_signal.get_object() as Object
	ObjectUtil.ref_target(proxy, from_signal_object)
	return proxy[METHOD]
