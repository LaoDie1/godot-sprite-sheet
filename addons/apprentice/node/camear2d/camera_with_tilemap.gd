#============================================================
#    Camera 2d Base
#============================================================
# - datetime: 2022-08-23 23:23:44
#============================================================
class_name BaseCameraByTileMap
extends BaseCameraDecorator


@export
var enabled := true
@export 
var tilemap : TileMap : 
	set(value):
		tilemap = value
		update_configuration_warnings()


var __readied = FuncUtil.execute(func():
		if self["__readied"]:
			return true
		if get_tree() != null:
			await get_tree().process_frame
			get_viewport().size_changed.connect(update_camera)
			update_camera()
		self["__readied"] = true
, true)


#============================================================
#  自定义
#============================================================
## 更新摄像机
func update_camera():
	if enabled:
		if camera != null and tilemap != null:
			_update_camera()


# 更新摄像机
func _update_camera():
	pass


