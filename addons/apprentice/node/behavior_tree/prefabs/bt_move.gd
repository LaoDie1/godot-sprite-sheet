#============================================================
#    Fbt Move
#============================================================
# - datetime: 2022-09-14 20:02:17
#============================================================

##  从 [member from] 的位置移动到 [member to] 的位置，发送移动信号，设置移动到的位置
extends BaseActionLeaf


##  已移动到目标位置
signal moved(new_position: Vector2)


@export
var move_speed := 100.0
@export
var from := ""
@export
var to := "" 


#(override)
func _do():
	var from_pos = bt_root.get_property(from) as Vector2
	var to_pos = bt_root.get_property(to) as Vector2
	var new_pos = from_pos.move_toward(to_pos, move_speed * bt_root.get_delta_time() )
	moved.emit( new_pos )


