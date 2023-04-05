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


var main : GenerateSpriteSheetMain = MAIN.instantiate()


func _enter_tree():
	# Initialization of the plugin goes here.
	get_editor_interface() \
		.get_editor_main_screen() \
		.add_child(main)
	main.set_anchors_preset(Control.PRESET_FULL_RECT, true)
	main.hide()
	main.exported.connect(func():
		get_editor_interface().get_resource_filesystem().scan()
		get_editor_interface().get_resource_filesystem().scan_sources()
	)
	


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


func _exit_tree():
	main.queue_free()
