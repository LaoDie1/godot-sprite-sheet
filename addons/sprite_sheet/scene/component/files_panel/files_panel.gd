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


var texture_item_group := SpriteSheetTextureItemGroup.new()


@onready var texture_container = $ScrollContainer/texture_container


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
	texture_rect.custom_minimum_size = Vector2(32, 32)
	texture_rect.dragged.connect(func(data_list: Array[Dictionary]):
		data_list.append(data)
	)
	texture_rect.double_clicked.connect(func():
		self.double_clicked.emit(data)
	)
	texture_item_group.add_item(texture_rect)

