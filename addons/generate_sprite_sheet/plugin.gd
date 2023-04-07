#============================================================
#    Generate Sprite Sheet
#============================================================
# - author: zhangxuetu
# - datetime: 2023-04-04 23:35:39
# - version: 4.0
#============================================================
@tool
extends EditorPlugin


const MAIN = preload("scene/generate_sprite_sheet.tscn")


var main : GenerateSpriteSheetMain


func _enter_tree():
	main = MAIN.instantiate()
	get_editor_interface() \
		.get_editor_main_screen() \
		.add_child(main)
	main.set_anchors_preset(Control.PRESET_FULL_RECT, true)
	main.hide()
	main.exported.connect(func():
		get_editor_interface().get_resource_filesystem().scan()
		get_editor_interface().get_resource_filesystem().scan_sources()
	)
	
	# 添加翻译
	await Engine.get_main_loop().process_frame
	update_translation()


func _has_main_screen():
	return true

func _make_visible(visible):
	main.visible = visible

func _get_plugin_name():
	return "SpriteSheet"

func _get_plugin_icon():
	var icon = get_editor_interface() \
		.get_base_control() \
		.get_theme_icon("ImageTexture", "EditorIcons")
	return icon


## 更新翻译 
func update_translation():
	
	
	# 扫描的翻译文件的路径
	var translation_path : String = "res://addons/generate_sprite_sheet/assets/translation/"
	# 扫描不同区域的翻译文件，根据后缀名判定
	var translation_map : Dictionary = {}
	var files = GenerateSpriteSheetUtil.scan_file(translation_path)
	for file in files:
		if file.get_extension() == "translation":
			var location = file.get_basename().get_extension()
			# 如果直接用 load 加载，Godot 会认为这是个 GDScript 文件
			translation_map[location] = ResourceLoader.load(file, "Translation")
	
	# 获取编辑器语言的翻译文件
	var editor_language : String = get_editor_interface() \
		.get_editor_settings() \
		.get('interface/editor/editor_language')
	var translation : Translation = translation_map.get(editor_language) as Translation
	if translation == null:
		# 如果没有则按照默认翻译
		translation = translation_map.get("")
	
	# 递归遍历更新
	var propertys = ["text", "tooltip_text"]
	var callback = func(node: Node):
		var value : String
		for property in propertys:
			if property in node:
				value = translation.get_message(node[property])
				if value:
					node[property] = value
		
		if node is TabContainer:
			for tab_child in node.get_children():
				tab_child.name = translation.get_message(tab_child.name)
		
		elif node is OptionButton or node is MenuButton or node is PopupMenu:
			var p_node : Node
			if node is OptionButton or node is PopupMenu:
				p_node = node
			elif node is MenuButton:
				p_node = node.get_popup()
			
			for idx in node.item_count:
				value = translation.get_message(p_node.get_item_text(idx))
				if value:
					p_node.set_item_text(idx, value)
	
	
	_translation_node(main, callback)
	


# 获取要翻译的节点
func _translation_node(node: Node, callback: Callable):
	for child in node.get_children():
		if (child is Button
			or child is Label
			or child is TabBar
			or child is TabContainer
			or child is OptionButton
			or child is MenuButton
			or child is PopupMenu
		):
			callback.call(child)
	for child in node.get_children():
		_translation_node(child, callback)
		child.child_entered_tree.connect( func(node):
			_translation_node(node, callback)
		)

