#============================================================
#    Log
#============================================================
# - datetime: 2022-09-07 19:35:12
#============================================================
## 日志工具
##
##方便输出具有格式化的字符串文本，使用示例：
##[codeblock]
##var path = "res://icon.svg"
##Log.info("已加载文件：%-50s | %s " % [path, path.get_file()])
##[/codeblock]
class_name Log


const DEFAULT_SEPARATOR = " "


#============================================================
#  自定义
#============================================================
##  输出普通信息
##[br]
##[br][code]params[/code]  参数数据。如果是数组类型的数据，则会按照 sep 参数进行分隔输出
##[br][code]sep[/code]  参数数据将会按照间隔分隔输出，如果这个参数开头为 “%”，则会对每个进行
##格式化之后输出
static func info(params, sep:=DEFAULT_SEPARATOR):
	if not params is Array:
		params = [params]
	print(_format_str(params, sep))


static func warning(params, sep:=DEFAULT_SEPARATOR):
	if not params is Array:
		params = [params]
	print_rich("[color=#ffdd65]%s[/color]" % _format_str(params, sep))


static func prompt(params, sep:=DEFAULT_SEPARATOR):
	if not params is Array:
		params = [params]
	print_rich("[color=#%s]%s[/color]" % [Color.LIME.to_html(false), _format_str(params, sep)])


static func error(params, sep:=DEFAULT_SEPARATOR):
	print_rich("[color=#ff786b]%s[/color]" % _format_str(params if params is Array else [params], sep))


static func rich(params, sep:=DEFAULT_SEPARATOR, color:=Color.WHITE):
	print_rich("[color=#%s]%s[/color]" % [
		color.to_html(false), 
		_format_str(params if params is Array else [params], sep)
	])


static func _format_str(params: Array, sep: String) -> String:
	if get_stack().size() == 0:
		return sep.join(params)
	var stack : Dictionary = get_stack()[2]
	var head := "%-60s" % [
		"{line}: {source} | {function}".format({
			"function": stack['function'],
			"source": stack['source'].get_file(),
			"line": stack['line'],
		}),
	]
	var v
	if sep.begins_with("%"):
		v = ""
		for i in params:
			v += sep % i
	else:
		v = sep.join(params)
	
	return "%s | %s" % [head , v]

# 格式化输出列
static func print_format(list: Array, column_format):
	assert(column_format is String or column_format is Array, "column_format 参数能是 [String, Array] 中的一种！")
	
	if column_format is String:
		column_format = [column_format]
	assert(column_format.size() > 0, "column_format 至少要一个格式化参数")
	if column_format.size() < list.size():
		var end = column_format.back()
		for i in list.size() - column_format.size():
			column_format.push_back(end)
	var format = "".join(column_format)
	print(format % list)

