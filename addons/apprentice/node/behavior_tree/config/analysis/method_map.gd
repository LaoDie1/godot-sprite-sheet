#============================================================
#    Method Map
#============================================================
# - datetime: 2023-02-07 16:48:21
#============================================================
# 设置行的方法

const DataClass = preload("data/data_class.gd")


var token : DataClass.Token
var objects : DataClass.Objects


#============================================================
#  内置
#============================================================
func _init(token: DataClass.Token, objects : DataClass.Objects):
	self.token = token
	self.objects = objects


#============================================================
#  自定义
#============================================================
# 映射设置方法
func map(struct_root: DataClass.Struct):
	FuncUtil.recursion([struct_root], func(struct: DataClass.Struct):
		var do_method := objects.get_do_method(struct.name)
		if do_method:
			
			# 执行具体方法的对象
			var call_method_target : Object = do_method.get_object(struct.node)
			if do_method.init_prop:
				ObjectUtil.set_object_property(call_method_target, do_method.init_prop)
			
			if call_method_target is Node:
				if not call_method_target.is_inside_tree():
					if objects.readable_name:
						call_method_target.name = struct.name
					struct.node.add_child(call_method_target, objects.readable_name)
				
				if  call_method_target is BaseDoNode:
					call_method_target.root = struct_root.root
			
			
			# 控制执行方法的叶节点
			var call_method : Callable = do_method.get_method(call_method_target)
			if not call_method.is_valid():
				if call_method_target is BaseDoNode:
					call_method = call_method_target.do
			
			if struct.do_object == null:
				struct.do_object = call_method_target
			if struct.method == null:
				struct.method = call_method
			
			var leaf = struct.node
			leaf._callable = call_method
			
			
			# 执行用户的上下文方法
			var context : Dictionary = {}
			context['root'] = struct_root.root
			context['struct'] = struct
			context['node'] = struct.node
			if struct.parent_struct:
				context['parent_node'] = struct.parent_struct.node
			if do_method.context.is_valid():
				do_method.context.call(context)
		
		return struct.children_struct
	)

