#============================================================
#    Preview Handle
#============================================================
# - author: zhangxuetu
# - datetime: 2023-04-03 13:54:37
# - version: 4.0
#============================================================
@tool
class_name GenerateSpriteSheet_PreviewHandle
extends MarginContainer


## 处理
signal handled(handle: Handle)


## 更新的对象的类型
enum {
	## 预览图像
	PREVIEW,
	## 选中的待处理图像
	PENDING_SELECTED,
}


@onready var from_color = %from_color
@onready var to_color = %to_color
@onready var color_threshold = %color_threshold
@onready var outline_color = %outline_color
@onready var color_threshold_label = %color_threshold_label


var button_group : ButtonGroup


class Handle:
	
	## 更新的对象的类型
	enum {
		## 预览图像
		PREVIEW,
		## 选中的待处理图像
		PENDING_SELECTED,
	}
	
	var update_type : int = PREVIEW
	
	var _callable: Callable
	var _check_callback: Callable
	
	func _init(type: int, callable: Callable, check_callback: Callable = Callable()):
		update_type = type
		_callable = callable
	
	## 执行处理图片
	##[br][code]texture_list[/code] 要修改的图片
	##[br][code]callback[/code] 处理完成之后调用的方法，这个方法需要有一个 Array[Texture2D] 类型的参数，接收处理后的图片
	##[br][code]show_message[/code] 如果检测不通过，则调用这个方法
	func execute(texture_list: Array, callback: Callable, show_message: Callable) -> void:
		if _check_callback.is_valid():
			var v = _check_callback.call()
			if v != null or v != "":
				show_message.call(v)
		
		var list : Array[Texture2D] = []
		for texture in texture_list:
			list.append(_callable.call(texture))
		callback.call(list)



#============================================================
#  内置
#============================================================
func _ready():
	var first_button = %operate_target.get_child(0) as Button
	button_group = first_button.button_group as ButtonGroup
	
	var button_list = %node_container.get_children().filter(func(node): return node is Button )
	GenerateSpriteSheetUtil.set_width_by_max_width(button_list)
	


# 执行这个方法处理图片
#[br][code]callback[/code] 这个回调需要有一个 [Texture2D] 参数，用于处理回调传入的每个图片
#[br][code]condition[/code] 没有参数，这个需要返回一个字符串，不返回则默认通过，用于检查是否继续执行的方法，以及不通过时提示的文字消息
func _emit_handle(callback: Callable, condition: Callable = Callable()):
	self.handled.emit(Handle.new(button_group.get_pressed_button().get_index(), callback, condition))


#============================================================
#  连接信号
#============================================================
func _on_resize_pressed():
	var _size = %size.get_value()
	_emit_handle(func(texture: Texture2D):
		return GenerateSpriteSheetUtil.resize_texture(texture, _size)
	, func():
		if _size.x <= 0 or _size.y <= 0:
			return "大小必须超过 0！"
	)


func _on_rescale_pressed():
	var scale_v = %scale.get_value()
	_emit_handle(func(texture: Texture2D):
		return GenerateSpriteSheetUtil.scale_texture(texture, scale_v)
	, func():
		if scale_v <= Vector2(0,0):
			return "缩放必须超过 0！"
	)


func _on_recolor_pressed():
	_emit_handle(func(texture: Texture2D):
		return GenerateSpriteSheetUtil.replace_color(texture, from_color.color, to_color.color, color_threshold.value)
	)


func _on_color_swap_pressed():
	var tmp = from_color.color
	from_color.color = to_color.color
	to_color.color = tmp


func _on_outline_pressed():
	_emit_handle(func(texture: Texture2D):
		return GenerateSpriteSheetUtil.outline(texture, outline_color.color)
	)


func _on_clear_transparency_pressed():
	_emit_handle(func(texture: Texture2D):
		var image = texture.get_image() as Image
		var rect = image.get_used_rect()
		var new_image = image.get_region(rect)
		return ImageTexture.create_from_image(new_image)
	)


func _on_cut_btn_pressed():
	var rect = Rect2i(%cut.get_value())
	_emit_handle(func(texture: Texture2D):
		var new_image = texture.get_image().get_region(rect)
		return ImageTexture.create_from_image(new_image)
	)


func _on_color_threshold_value_changed(value):
	pass # Replace with function body.
	color_threshold_label.text = str(value)
