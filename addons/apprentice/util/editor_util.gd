#============================================================
#    Editor Tool
#============================================================
# - datetime: 2022-12-23 19:34:16
#============================================================
## 编辑器工具类（请注意，它只能用在编辑器中，游戏运行后将无效）
class_name EditorUtil

##  获取编辑器接口
##[br]
##[br][code]return[/code]  
static func get_editor_interface() -> EditorInterface:
	return DataUtil.get_meta_data("EditorUtil_get_editor_interface", func(): 
		# 默认值
		return EditorScript.new().get_editor_interface() 
	)

## 获取编辑器根节点
static func get_editor_root() -> Viewport:
	return get_editor_interface().get_viewport()

##  获取编辑器主题图标
##[br]
##[br][code]name[/code]  图标名称
##[br]
##[br][code]return[/code]  返回这个图标
static func get_editor_theme_icon(name: StringName) -> Texture:
	return get_editor_interface().get_base_control().get_theme_icon(name, "EditorIcons")


##  获取选中的节点
##[br]
##[br][code]return[/code]  返回选中的节点列表
static func get_selected_nodes() -> Array[Node]:
	return get_editor_interface().get_selection().get_selected_nodes()


##  获取这个路径的文件系统目录
##[br]
##[br][code]path[/code]  目录路径
##[br]
##[br][code]return[/code]  返回这个编辑器文件系统目录
static func get_filesystem_path(path: String) -> EditorFileSystemDirectory:
	return get_editor_interface().get_resource_filesystem().get_filesystem_path(path)


## 获取当前选中的文件所在目录，如果没有选中，则
static func get_selected_dir():
	var list = get_editor_interface().get_selected_paths()
	if len(list) > 0:
		var path = list[0] as String
		if DirAccess.dir_exists_absolute(path):
			return path
		else:
			return path.get_base_dir()
	return ""


## 获取正在编辑的场景根节点
static func get_edited_scene_root() -> Node:
	return get_editor_interface().get_edited_scene_root()


## 设置场景根节点
static func set_edited_scene_root(node: Node) -> void:
	var scene = PackedScene.new()
	scene.pack(node)
	get_editor_interface().edit_resource(scene)
	get_editor_interface().get_selection().add_node(node)
	get_editor_interface().edit_node(node)


##  获取当前编辑器的编辑视图名称（2D、3D、Script、AssetLib），如果没有这几个，则返回空字符串
static func get_main_screen_editor_name() -> String:
	var class_to_node_map = DataUtil.get_meta_data("EditorUtil_clas_to_node_map", func():
		return {
			"CanvasItemEditor": null,
			"Node3DEditor": null,
			"ScriptEditor": null,
			"EditorAssetLibrary": null,
			"CPUParticles3DEditor": null,
			"GPUParticles3DEditor": null,
			"MeshInstance3DEditor": null,
			"MeshLibraryEditor": null,
			"MultiMeshEditor": null,
			"Skeleton2DEditor": null,
			"Sprite2DEditor": null,
			"NavigationMeshEditor": null,
		}
	)
	
	if class_to_node_map.CanvasItemEditor == null:
		# 扫描子节点
		var main_screen = get_editor_interface().get_editor_main_screen()
		for child in main_screen.get_children():
			var class_ = child.get_class()
			if class_to_node_map.has(class_):
				class_to_node_map[class_] = child
	
	# 2D
	if class_to_node_map.CanvasItemEditor.visible:
		return "2D"
	# 3D
	if class_to_node_map.Node3DEditor.visible:
		return "3D"
	# Script
	if class_to_node_map.ScriptEditor.visible:
		return "Script"
	# AssetLib
	if class_to_node_map.EditorAssetLibrary.visible:
		return "AssetLib"
	return ""


##  获取插件名（这个插件需要是插件可开启或关闭的插件对象，而非自定义的随处放置的插件对象）
##[br]
##[br][code]plugin[/code]  插件对象
##[br]
##[br][code]return[/code]  返回这个插件的插件名
static func get_plugin_name(plugin: EditorPlugin) -> StringName:
	return plugin.get_script().resource_path.get_base_dir().get_file()


##  重新加载插件
##[br]
##[br][code]plugin[/code]  
static func reload_plugin(plugin: EditorPlugin) -> void:
	if plugin != null:
		var plugin_name = get_plugin_name(plugin)
		var editor_interface = get_editor_interface()
		editor_interface.set_plugin_enabled(plugin_name, false)
		await get_editor_interface().get_tree().create_timer(0.1).timeout
		editor_interface.set_plugin_enabled(plugin_name, true)
		print("已重新加载 ", plugin_name, " 插件")
	else:
		printerr("<plugin 参数为值 null>")


##  文件系统定位到这个路径
##[br]
##[br][code]path[/code]  要定位的路径
static func navigate_to_path(path: String) -> void:
	get_editor_interface().get_file_system_dock().navigate_to_path(path)


static func get_editor_node_map() -> Dictionary:
	return DataUtil.get_meta_data("EditorUtil_get_editor_node_by_class", 
		func():
			var node_map : Dictionary = {}
			FuncUtil.recursion(
				EditorUtil.get_editor_root(),
				func(node: Node):
					if node_map.has(node.get_class()):
						node_map[node.get_class()].push_back(node)
					else:
						var list : Array[Node] = []
						list.push_back(node)
						node_map[node.get_class()] = list
					return node.get_children()
			)
			return node_map
	)


##  根据类名获取编辑器节点
static func get_editor_node_by_class(_class_name: StringName) -> Array[Node]:
	return get_editor_node_map().get(_class_name, Array([], TYPE_OBJECT, "Node", null))


## 获取创建场景根节点的按钮
static func get_create_root_node_buttons() -> Dictionary:
	var scene_tree_dock = get_editor_node_by_class("SceneTreeDock").front() as Node
	var create_root_scene_button_container = scene_tree_dock.get_child(2) \
		.get_child(1) \
		.get_child(0) \
		.get_child(0)
	
	return {
		"2D Scene": create_root_scene_button_container.get_child(0),
		"3D Scene": create_root_scene_button_container.get_child(1),
		"User Interface": create_root_scene_button_container.get_child(2),
		"Other Node": create_root_scene_button_container.get_parent().get_child(2),
	}


##  获取创建新节点弹窗的节点
static func get_create_new_node_dialog() -> Window:
	var scene_tree_dock = get_editor_node_by_class("SceneTreeDock").front() as Node
	return scene_tree_dock.get_child(4)


##  获取文件系统的鼠标菜单
static func get_file_system_dock_menu() -> PopupMenu:
	var file_dock = get_editor_interface().get_file_system_dock()
	return file_dock.get_child(2) as PopupMenu


##  获取2D编辑器画布节点
static func get_2d_editor() -> Control:
	var list = get_editor_node_by_class("CanvasItemEditor")
	if list.size() > 0:
		return list[0]
	return null


##  添加2D编辑器工具按钮
##[br]
##[br][code]button[/code]  
##[br][code]add_separator[/code]  
static func add_2d_editor_tool_button(button: BaseButton):
	var hbox := DataUtil.get_meta_data("EditorUtil_add_2d_editor_tool_button_2d_hbox", func():
		var hbox = HBoxContainer.new()
		var canvas = get_2d_editor() #as CanvasItemEditor
		var tool_button_container := canvas.get_child(0) as Node
		tool_button_container.add_child.call_deferred(hbox)
		return hbox
	) as Control
	
	hbox.add_child(button)


##  获取当前脚本编辑器
static func get_script_editor() -> ScriptEditor:
	return get_editor_interface().get_script_editor()

## 获取前编辑的脚本
static func get_current_script() -> Script:
	return get_script_editor().get_current_script()

static func get_current_script_code_editor() -> CodeEdit:# -> CodeTextEditor:
	var code_edit =  get_script_editor_code_editor( get_script_editor() )
	return code_edit

static func get_script_editor_code_editor(script_editor: ScriptEditor) -> CodeEdit:
	if script_editor:
		var node = script_editor.get_current_editor()
		return node.get_child(0).get_child(0).get_child(0)
	return null


##  获取当前脚本编辑器行列位置
##[br]x 为列，y 为行
##[br][code]return[/code]  返回行列位置，如果没有代码编辑，则返回 [code]Vector2i(-1, -1)[/code]
static func get_current_script_editor_column_line() -> Vector2i:
	var code_edit = EditorUtil.get_current_script_code_editor()
	if code_edit:
		return Vector2i( code_edit.get_caret_column(), code_edit.get_caret_line())
	return Vector2i(-1, -1)

static func get_current_script_editor_line() -> int:
	var code_edit = EditorUtil.get_current_script_code_editor()
	if code_edit:
		return code_edit.get_caret_line()
	return -1

static func get_current_script_editor_column() -> int:
	var code_edit = EditorUtil.get_current_script_code_editor()
	if code_edit:
		return code_edit.get_caret_column()
	return -1


static func get_current_script_editor_line_text() -> String:
	var line = EditorUtil.get_current_script_editor_line()
	if line > -1:
		var code_edit = get_current_script_code_editor()
		return code_edit.get_line(line)
	return ""
