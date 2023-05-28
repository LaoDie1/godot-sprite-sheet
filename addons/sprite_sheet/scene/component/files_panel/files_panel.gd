#============================================================
#    Files Panel
#============================================================
# - author: zhangxuetu
# - datetime: 2023-05-28 22:03:30
# - version: 4.0
#============================================================
@tool
extends PanelContainer


signal double_clicked(data: Dictionary)


const ITEM_SCENE = preload("../texture_node_item/item.tscn")
const ITEM_SCRIPT = preload("../texture_node_item/item.gd")

@export var item_size : Vector2 = Vector2(32, 32):
	set(v):
		item_size = v
		
		if item_size_spin_box == null:
			await ready
		if item_size_spin_box.value != item_size.x:
			item_size_spin_box.value = item_size.x
		for node in texture_item_group.get_item_node_list():
			node.custom_minimum_size = item_size
		


var __init_node__ = SpriteSheetUtil.auto_inject(self)

var texture_container : HFlowContainer
var item_size_spin_box : SpinBox

var texture_item_group := SpriteSheetTextureItemGroup.new()


func _ready():
	var count = [0]
	var callback = func():
		var files = SpriteSheetUtil.scan_file("res://", true)
		for path in files:
			if path.get_extension() in ["png", "jpg", "jpeg", "bmp", "svg"]:
				count[0] += 1
				if count[0] % 10 == 0:
					await Engine.get_main_loop().process_frame
				add_texture_file(path)
	
	if visible:
		callback.call()
	else:
		visibility_changed.connect(callback, Object.CONNECT_ONE_SHOT)


func add_texture_file(path: String):
	var texture_rect = ITEM_SCENE.instantiate() as ITEM_SCRIPT
	texture_container.add_child(texture_rect)
	
	var texture = load(path)
	var data = {
		"type": SpriteSheetUtil.DragType.Files,
		"texture": texture,
		"path": path,
	}
	texture_rect.set_data(data)
	texture_rect.custom_minimum_size = item_size
	texture_rect.dragged.connect(func(data_list: Array[Dictionary]):
		data_list.append(data)
	)
	texture_rect.double_clicked.connect(func():
		self.double_clicked.emit(data)
	)
	texture_item_group.add_item(texture_rect)


func _on_spin_box_value_changed(value):
	if value != item_size.x:
		item_size = Vector2(value, value)
