#============================================================
#    Analysis
#============================================================
# - datetime: 2023-02-07 16:09:06
#============================================================
# 分析文档数据的内容

const DataClass = preload("data/data_class.gd")


# 匹配缩进空白字符
var _indent_regex : RegEx = RegEx.new()
var __init_indent_regex__ = (func(): _indent_regex.compile("^(\\s*)")).call()

var _data_list : Array[DataClass.Struct] = []


var token : DataClass.Token
var structures : DataClass.Struct


#============================================================
#  内置
#============================================================
func _init(token: DataClass.Token):
	self.token = token


#============================================================
#  自定义
#============================================================
## 获取字符串缩进
func _get_indent(string: String) -> int:
	return _indent_regex.search(string).get_string(0).length()


## 获取这一行的类型
func get_type(string: String) -> String:
	if string:
		var split = string.split(" ")
		var type : String 
		if split.size() == 1:
			type = string.left(1)
		elif split.size() > 1:
			type = split[0]
		else:
			return ""
		
		if token.has_type(type):
			return type.strip_edges()
	
	# 默认照 action 处理
	return ""


## 获取名称
func get_desc_name(line: String, type: String) -> String:
	return line.trim_prefix(type).strip_edges()


## 获取结构数据
func _get_struct_data(desc_name: String, token: String, line: String) -> DataClass.Struct:
	var struct = DataClass.Struct.new()
	struct.name = desc_name
	struct.token = token
	struct.line = token
	return struct


##  分析文档字符串结构
func parse(document: String) -> DataClass.Struct:
	structures = _get_struct_data("root", "root", "")
	
	var indents = [-1]	# 根节点缩进 -1
	var parents = [structures]
	var last_struct = [structures]
	FuncUtil.foreach(document.split("\n" if document.find("\r\n")==-1 else "\r\n"), 
		func(index, line: String):
			# 空白行跳过
			if line.strip_edges() != "":
				var indent = _get_indent(line)
				if indent > indents.back():
					# 向右缩进了
					indents.push_back(indent)
					parents.push_back(last_struct[0])
				
				elif indent < indents.back():
					# 向左缩进了
					indents.pop_back()
					parents.pop_back()
				
				line = line.strip_edges(true, false)
				
				# 添加数据
				var type = get_type(line)
				var name = get_desc_name(line, type)
				var struct = _get_struct_data(name, type, line)
				var parent_struct = parents.back() as DataClass.Struct
				parent_struct.children_struct.append(struct)
				
				_data_list.append(struct)
				last_struct[0] = struct
				
	)
	
	return structures


