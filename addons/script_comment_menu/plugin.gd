#============================================================
#    Plugin
#============================================================
# - datetime: 2022-06-11 11:26:00
# - datetime: 2022-07-17 14:54:39
#============================================================
@tool
extends EditorPlugin



var menu_button : MenuButton 
var util_add_menu := ScriptCommentMenuConstant.AddMenu.new()

var _sub_menus = [
	_ScriptMenu_Comments.new(),
	_ScriptMenu_Overrides.new(),
]


func _enter_tree():
	call_deferred("_init_data")


func _exit_tree():
	if menu_button:
		menu_button.queue_free()
	for sub in _sub_menus:
		sub._uninstall()


func _init_data():
	# 添加菜单按钮
	menu_button = MenuButton.new()
	menu_button.text = "代码工具"
	menu_button.switch_on_hover = true
	util_add_menu.add_script_editor_menu(menu_button)
	
	for sub in _sub_menus:
		sub.init_menu(menu_button)



