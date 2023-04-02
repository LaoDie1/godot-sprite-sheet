#============================================================
#    Sound Config Resource
#============================================================
# - author: zhangxuetu
# - datetime: 2023-03-10 21:43:09
# - version: 4.x
#============================================================
# 声音配置
class_name SoundConfig
extends Resource


@export
var stream : AudioStream
@export_range(0, 1, 0.001, "or_greater")
var from_position : float = 0.0
@export_range(-80, 24, 0.001, "or_less", "or_greater")
var volume_db : float = 0.0
@export_range(0, 10, 0.001, "or_greater")
var pitch_scale : float = 1.0
## 播放停止时间，从 0 秒开始到这个时间时停止播放
@export
var stop_time : float = 0.0
@export
var loop : bool = false:
	set(v):
		if loop != v:
			loop = v
			if loop:
				_audio_player.finished.connect(_next_play)
				_stop_timer.timeout.connect(_next_play, Object.CONNECT_DEFERRED)
			else:
				_audio_player.finished.disconnect(_next_play)
				_stop_timer.timeout.disconnect(_next_play)


var _audio_player : AudioStreamPlayer2D = AudioStreamPlayer2D.new()
var _stop_timer : Timer = Timer.new()


func add_to(node: Node) -> void:
	_audio_player.stream = stream
	_audio_player.volume_db = volume_db
	_audio_player.pitch_scale = pitch_scale
	
	_stop_timer.timeout.connect(_audio_player.stop)
	_stop_timer.one_shot = true
	_audio_player.add_child(_stop_timer)
	
	node.add_child(_audio_player)


func _next_play():
	if is_instance_valid(_audio_player):
		_audio_player.play(from_position)
		if stop_time > 0:
			_stop_timer.start((stop_time - from_position) / pitch_scale)
#	else:
#		push_error(" 声音播放器无效，播放失败")


func get_audio_player() -> AudioStreamPlayer2D:
	return _audio_player


func play(from_position : float = -1) -> void:
	if from_position >= 0:
		self.from_position = from_position
	_next_play()


func stop() -> void:
	if is_instance_valid(_audio_player):
		_audio_player.stop()

