#============================================================
#    Generate Node
#============================================================
# - datetime: 2023-02-07 16:26:41
#============================================================
# 生成文档内容所需的节点

const DataClass = preload("data/data_class.gd")


var token : DataClass.Token
var objects : DataClass.Objects


#============================================================
#  内置
#============================================================
func _init(token: DataClass.Token, objects: DataClass.Objects):
	self.token = token
	self.objects = objects


#============================================================
#  自定义
#============================================================
func execute(struct_root: DataClass.Struct) -> BTNodeUtil.ROOT:
	var root : Node = BTNodeUtil.ROOT.new()
	struct_root.root = root
	struct_root.node = root
	
	_generate_child_node(struct_root)
	
	return root


# 生成节点结构
func _generate_child_node(parent_struct: DataClass.Struct):
	for struct in parent_struct.children_struct:
		_add_struct_node(struct, parent_struct)
	
	for struct in parent_struct.children_struct:
		_generate_child_node(struct)
	


## 添加 bt 结构节点
func _add_struct_node(struct: DataClass.Struct, parent_struct: DataClass.Struct) -> Node:
	var mean : DataClass.Token.MeanItem = token.get_mean_by_token(struct.token)
	var node = mean.create_node()
	struct.root = parent_struct.root
	struct.node = node
	struct.parent_struct = parent_struct
	
	objects.add_struct_node(struct.node, struct.name, struct.token, parent_struct.node)
	
	return node

