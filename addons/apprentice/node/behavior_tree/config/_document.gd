#============================================================
#    Document
#============================================================
# - datetime: 2023-02-07 17:42:30
#============================================================

class_name Document


const DataClass = preload("analysis/data/data_class.gd")
const Analysis = preload("analysis/analysis.gd")
const GenerateNode = preload("analysis/generate_node.gd")
const MethodMap = preload("analysis/method_map.gd")


# [解析处理对象]
var analysis : Analysis
var generate_node : GenerateNode
var method_map : MethodMap


# [存储数据对象]
var document : String = ""
var struct_root : DataClass.Struct
var root : BTNodeUtil.ROOT


#============================================================
#  自定义
#============================================================
# 解析这个文件
static func parse_by_path(
	path: String, 
	to: Node, 
	config: Dictionary = {}, 
	handle_string: Callable = Callable()
) -> Document:
	var string = FileUtil.read_as_text(path)
	if handle_string.is_valid():
		string = handle_string.call(string)
	return parse_by_string(string, to, config)


# 解析字符串
##[br]
##[br][code]document_string[/code]  配置文档内容
##[br][code]to[/code]  生成的节点添加到的目标节点
##[br][code]config[/code]  配置据
##[br][code]return[/code]  返回结构生成后的文档对象
static func parse_by_string(document_string: String, to: Node, config: Dictionary = {}) -> Document:
	var document = Document.new()
	document.execute(document_string, to, config)
	return document as Document


# 执行创建
func execute(document_string: String, to: Node, config: Dictionary = {}):
	var token_data = config.get("token", {})
	# 默认配置数据，如果传入的数据已经有了，则默认的数据会被覆盖
	token_data['mean'] = ObjectUtil.merge_array([
			# & 代表下面的 Sequence 类，创建的时候创建这个类的节点
			# 这个值需要是 Class 或 Script 类型，且创建的类型为 Node 类型
			{ "name": "&", "type": BTNodeUtil.SEQUENCE, },
			{ "name": "|", "type": BTNodeUtil.SELECTOR },
			{ "name": "?", "type": BTNodeUtil.Extention.CONDITION,
				"init_prop": { 
					"_callable": func(): return false 
				}
			},
			{ "name": [">", ""], "type": BTNodeUtil.Extention.ACTION, 
				"init_prop": {
					"_callable": func(): pass 
				} 
			}
		], token_data.get("mean", []))
	var token = DataClass.Token.new(token_data)
	
	
	var default_objects_data : Dictionary = {
		"readable_name": false,	# 具有可读性的节点名称
		"add_to_scene": true,	# 添加到场景中
		"new_node": func(new_node: Node): pass,	# 新创建的节点
		"do_method": [
#			{
#				"name": "移动到位置",		# 设置下面属性的目标对象的描述名称
#				"type": BaseDoNode,		# 创建的对象类型
#				"method": func(): print("hello"),	# String 或 Callable 类型，执行调用这个类型对象的方法
#				"context": func(context: Dictionary):	# 上下文方法，解析完成创建对象后，调用这个方法，这个方法存储着整个结构，以及 root 和当前节点
#					var node = context["node"]
#					print(
#						" >>> ", ScriptUtil.get_object_script_path(self), "\n", 
#						"     测试 context", context
#					)
#					,
#				"init_prop": {  # 这个节点初始化设置属性
#					"move_controller": Node.new(),
#				},
#			},
		],
		"match_node_list": [],
	}
	default_objects_data.merge(config.get("objects", {}), true)
	var objects = DataClass.Objects.new(default_objects_data)
	
	
	# 解析文档
	analysis = Analysis.new(token)
	struct_root = analysis.parse(document_string)
	
	
	# 生成节点
	generate_node = GenerateNode.new(token, objects)
	root = generate_node.execute(struct_root)
	if objects.add_to_scene:
		if objects.readable_name:
			root.name = "root"
		to.add_child.call_deferred(root, objects.readable_name)
		
		FuncUtil.call_once_in_tree(root, func():
			var owner = root.get_parent().owner
			if owner == null: owner = root.get_parent()
			root.owner = owner
			for child in NodeUtil.get_all_child(root):
				child.owner = owner
			
		)
	
	# 配置方法
	method_map = MethodMap.new(token, objects)
	method_map.map(struct_root)
	
	
	var file = ScriptUtil.get_object_script_path(self).get_file()
	var format = [ "%-20s", "%-12s", "%-24s", "%-25s", "%-35s"]
	Log.print_format(["[source]", "[token]", "[script]", "[desc_name]", "[object]", "[method]"], format)
	FuncUtil.recursion( [struct_root], func(struct: DataClass.Struct):
		
		Log.print_format([
			file, 
			struct.token, 
			FileUtil.get_object_file(struct.get_type()).get_file(), 
			struct.name,
			struct.do_object if struct.do_object else "",
			struct.get_method() if struct.get_method().is_valid() else "",
		], format)
		
		return struct.children_struct
	)
	
	

