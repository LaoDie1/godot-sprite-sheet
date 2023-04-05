#============================================================
#    File Tree
#============================================================
# - author: zhangxuetu
# - datetime: 2023-03-31 00:42:15
# - version: 4.0
#============================================================
@tool
class_name GenerateSpriteSheet_FileTree
extends VBoxContainer


# 新增 item
signal added_item(item: TreeItem)
# 选中某个 item
signal selected(path_type: int, path: String)
# 双击某个 item
signal double_clicked(path_type: int, path: String)
# 开始拖拽。[code]data_list[/code] 数据为选中的 item 的数据列表
signal dragged(data_list: Array[Dictionary])


enum ConfKey {
	SCAN_DIR_KEY
}


enum PathType {
	DIRECTORY,
	FILE,
}


@onready var tree : Tree = $tree


var _last_filter : Callable
var _root : TreeItem


#============================================================
#  SetGet
#============================================================
func _get_config_data() -> Dictionary:
	return GenerateSpriteSheetUtil.get_config_data("file_tree")

## 获取所有选中的 item
func get_selected_items() -> Array[TreeItem]:
	var all_items : Array[TreeItem] = []
	var selected_item = tree.get_selected()
	while selected_item:
		all_items.append(selected_item)
		selected_item = tree.get_next_selected(selected_item)
	return all_items


#============================================================
#  内置
#============================================================
func _ready():
	var dir = _get_config_data().get(ConfKey.SCAN_DIR_KEY, "")
	if dir and DirAccess.dir_exists_absolute(dir):
		update_tree(dir, GenerateSpriteSheetUtil.get_texture_filter())



#============================================================
#  自定义
#============================================================
func _create_item(path_type: int, path: String, parent_item: TreeItem, item: TreeItem = null) -> TreeItem:
	if item == null:
		item = parent_item.create_child()
	item.set_text(0, path.get_file())
	# 记录数据
	var data = {}
	data['path_type'] = path_type
	data['path'] = path
	item.set_metadata(0, data)
	# 设置折叠
	item.collapsed = true
	self.added_item.emit(item)
	return item


func _update_tree_item(parent_directory: String, parent_item: TreeItem):
	# 扫描目录
	for sub_dir in GenerateSpriteSheetUtil.scan_directory(parent_directory):
		var item = _create_item(PathType.DIRECTORY, sub_dir, parent_item)
		if (parent_item.get_parent() == null 
			or not parent_item.get_parent().collapsed
		):
			_update_tree_item(sub_dir, item)
	
	# 扫描目录下的所有文件
	for file in GenerateSpriteSheetUtil.scan_file(parent_directory):
		if _last_filter.is_null() or _last_filter.call(file):
			_create_item(PathType.FILE, file, parent_item)


## 更新整个文件目录
func update_tree(directory: String, filter: Callable = Callable()):
	_get_config_data()[ConfKey.SCAN_DIR_KEY] = directory
	
	_last_filter = filter
	directory = directory.trim_suffix("/")
	
	tree.clear()
	_root = tree.create_item()
	_create_item(PathType.DIRECTORY, directory, null, _root)
	_root.collapsed = false



#============================================================
#  连接信号
#============================================================
func _on_tree_cell_selected():
	# 选中item
	var item : TreeItem = tree.get_selected()
	if item:
		var data : Dictionary = item.get_metadata(0) as Dictionary
		var path_type : int = data.path_type
		var path : String = data.path
#		match data.path_type:
#			PathType.FILE:
#				if FileAccess.file_exists(path):
#					pass
#			PathType.DIRECTORY:
#				if DirAccess.dir_exists_absolute(path):
#					pass
		
		self.selected.emit(path_type, path)


func _on_tree_item_activated():
	# 双击 item
	var item : TreeItem = tree.get_selected()
	if item:
		var data = item.get_metadata(0) as Dictionary
		self.double_clicked.emit(data.path_type, data.path)


func _on_tree_dragged(item: TreeItem, data_ref: Dictionary):
	# 获取选中的 item
	var all_items := get_selected_items()
	if not all_items.has(item):
		all_items.append(item)
	
	# 拖拽item
	var data_list : Array[Dictionary] = []
	var label = Label.new()
	for selected_item in all_items:
		data_list.append(selected_item.get_metadata(0))
	
	data_ref['type'] = GenerateSpriteSheetUtil.DragType.FileTree 
	data_ref.data = data_list
	label.text = item.get_text(0)
	set_drag_preview(label)
	
	self.dragged.emit(data_list)


func _on_tree_item_collapsed(item: TreeItem):
	if not item.collapsed:
		# 移除子节点
		var list = item.get_children()
		list.reverse()
		for sub_item in list:
			item.remove_child(sub_item)
		
		# 更新 tree item
		var data = item.get_metadata(0) as Dictionary
		if data.path_type == PathType.DIRECTORY:
			_update_tree_item(data.path, item)
		
