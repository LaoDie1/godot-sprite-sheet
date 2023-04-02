#============================================================
#    Conn Anonymous Func
#============================================================
# - datetime: 2023-02-25 17:03:52
#============================================================
# 连接匿名方法 (弃用)
class_name _ScriptMenu_ConnAnonymousFunc
extends _ScriptMenu_SubItem



#(override)
func _init_menu(menu_button):
	add_separator(menu_button)
	add_menu_item(menu_button, "生成连接的匿名方法", {}, _gene_anony_func)


# 生成接的名方法
func _gene_anony_func():
	pass
	
	get_editor_interface().get_script_editor()
	
	

