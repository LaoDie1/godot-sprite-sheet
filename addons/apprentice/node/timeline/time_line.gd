#============================================================
#    Timeline
#============================================================
# - datetime: 2022-11-25 19:44:59
#============================================================
##时间线
##
##[br]播放时经过这个时间时将会发出 [signal elapsed] 信号。使用 [method push_key] 顺着上个
##时间向后添加时间线。
##[br]
##[br]用于对有时间段经过处理的功能，比如角色技能事件，在达到这个事件的 idx 时进行对应的动作的处理
##[br]
##[br]如果有添加时间点数据，则必会发出第一个时间点的 [signal elapsed] 的信号
class_name TimeLine
extends Node


## 经过时间点
##[br]
##[br][code]idx[/code]  这个时间点关键帧的索引号
##[br][code]time[/code]  经过的关键帧时间开始播放的时长
##[br][code]data[/code]  关键帧上的数据。一般为 ID、 [Dictionary] 类型对象或自定义类对象用
##以处理数据
signal elapsed(idx: int, time: float, data)
## 开始播放
signal played
## 播放已暂停
signal paused
## 停止了播放
signal stopped
## 播放完成
signal finished
## 继续播放
signal continue_played


## 最小间隔时间
const DEFAULT_MIN_INTERVAL_TIME : float = 1e-06


@export_enum("Physics", "Idle")
var process_callback : int = 1


# 时间段对应的数据
var _key_time_to_data_map : Dictionary = {}
# 最大时间
var _max_time : float = 0.0
# 关键帧点先后时间顺序列表
var _key_priority_list : Array = []
# 用于播放的计时器
var _play_timer := Timer.new()

# 当前播放到的时间点索引
var _key_index_of_play : int = -1



#============================================================
#  SetGet
#============================================================
##  这个时间线是否为空，如果为空，则是没有加关键点，不能执行
func is_empty() -> bool:
	return _key_time_to_data_map.size() == 0

## 是否正在播放
func is_playing() -> bool:
	return _key_index_of_play != -1

##  获取播放时间长度
func get_time_length() -> float:
	return _max_time

##  获取关键点列表，这些点按照大小进行排序
func get_key_time_list() -> Array:
	if _key_priority_list:
		return _key_priority_list
	else:
		_key_priority_list = _key_time_to_data_map.keys()
		_key_priority_list.sort()
		return _key_priority_list

## 根据 idx 获取对应索引的关键帧的数据
func get_key_data_by_idx(idx: int):
	return get_key_data_by_time(get_key_time_list()[idx])

## 根据时间获取这个时间上的关键帧数据
func get_key_data_by_time(time: float):
	return _key_time_to_data_map.get(time)

##  获取这个 idx 的时间
func get_key_time_by_idx(idx: int) -> float:
	return get_key_time_list()[idx]

##  获取这个时间的位置
func get_key_idx_by_time(time: float) -> int:
	return get_key_time_list().find(time)

##  获取这个关键帧位置的时间长度
func get_key_time_length(idx: int) -> float:
	var key_list = get_key_time_list()
	# 这个关键帧的开始播放的时间
	var key_time = key_list[idx]
	var time = 0.0
	if idx > 0:
		var last_key_time = key_list[idx - 1]
		time = key_time - last_key_time
	else:
		time = key_time
	# 在这里对时间位数进行了截取，超过5位小数的部分数字会丢失
	return snapped(time, 1e-05)

##  获取已经经过的时间
func get_time_left() -> float:
	return get_key_time_length( get_current_key_index() ) - _play_timer.time_left

## 获取当前关键点时间索引
func get_current_key_index() -> int:
	return _key_index_of_play

## 获取 key 数量
func get_key_count() -> int:
	return _key_time_to_data_map.size()

func get_id_list() -> Array:
	return range(_key_time_to_data_map.size())


#============================================================
#  内置
#============================================================
func _ready():
	if not _play_timer.is_inside_tree():
		_init_play_timer(self)



#============================================================
#  数据
#============================================================
##  在这个时间点上添加数据，如果之前已经设置过，添加则会被覆盖
##[br]
##[br][code]data[/code]  添加的数据
##[br][code]time[/code]  设置的时间点
func add_key(data, time: float):
	_key_time_to_data_map[time] = data
	if time > _max_time:
		_max_time = time
	_key_priority_list.clear()


##  紧跟最后一个添加数据。
##[br]
##[br][code]data[/code]  关键帧数据
##[br][code]offset_time[/code]  最大时间向后的时间长度，时间小数位数不能过小，否则播放时将会被舍去，
##最小能有 5 位小数，所以默认的 [member DEFAULT_MIN_INTERVAL_TIME] 这个时间的值会在播放时
##自动变为 0 秒时间
func push_key(data, offset_time: float = -1.0):
	if offset_time <= 0:
		offset_time = DEFAULT_MIN_INTERVAL_TIME
		if is_empty():
			offset_time = 0
	add_key(data, _max_time + offset_time)


##  插入关键帧
##[br]
##[br][code]idx[/code]  插入的位置
##[br][code]data[/code]  插入的数据
##[br][code]time[/code]  向后移动的时间长度
func insert_key(idx: int, data, time: float = DEFAULT_MIN_INTERVAL_TIME):
	var time_list = get_key_time_list()
	# 后面的数据都要后移
	var tmp_data
	var t
	for i in range( idx, time_list.size() ):
		t = time_list[i]
		tmp_data = _key_time_to_data_map[t]
		_key_time_to_data_map.erase(t)
		_key_time_to_data_map[t + time] = tmp_data
	_max_time += time
	
	add_key(data, time)


##  修改id的关键帧时间
##[br]
##[br][code]idx[/code]  修改的位置
##[br][code]time[/code]  修改时间
func alter_time_by_id(idx: int, time: float):
	var data = get_key_data_by_idx(idx)
	var previous_time = get_key_time_by_idx(idx)
	
	# 这个id之后的时间全部延长
	var time_list = get_key_time_list()
	var tmp_time
	var tmp_data
	for i in range(idx+1, len(time_list)):
		tmp_time = time_list[i]
		tmp_data = _key_time_to_data_map[tmp_time]
		# 重新设置时间
		_key_time_to_data_map.erase(tmp_time)
		_key_time_to_data_map[tmp_time - previous_time + time] = tmp_data
	
	# 修改这个Id的时间为新的时间
	_key_time_to_data_map.erase(previous_time)
	_key_time_to_data_map[time] = data
	_key_priority_list.clear()


##  根据时间修改关键帧上的数据
func alter_key_data_by_time(time: float, data):
	_key_time_to_data_map[time] = data


##  修改关键帧数据
func alter_key_data_by_idx(idx: int, data):
	var time = get_key_time_by_idx(idx)
	alter_key_data_by_time(time, data)


##  根据时间移除关键帧
func remove_key_by_time(time: float):
	var idx = get_key_idx_by_time(time)
	_key_time_to_data_map.erase(time)
	
	# 之前的时间总计
	var time_list = get_key_time_list()
	var previous_time = 0.0
	for i in idx - 1:
		previous_time += time_list[i]
	
	# 后面的时间
	var tmp_time
	var tmp_data
	for i in range(idx + 1, time_list.size()):
		tmp_time = time_list[i]
		tmp_data = _key_time_to_data_map[tmp_time]
		# 去掉旧的时间
		_key_time_to_data_map.erase(tmp_time)
		# 设置新的时间
		_key_time_to_data_map[tmp_time - time + previous_time] = tmp_data
	
	_key_priority_list.clear()


##  根据索引移除关键帧
func remove_key_by_idx(idx: int):
	# 移除的索引的时间
	var removed_time : float = get_key_time_by_idx(idx)
	remove_key_by_time(removed_time)



#============================================================
#  播放
#============================================================
# 初始化播放计时器
func _init_play_timer(host: Node):
	_play_timer.one_shot = true
	_play_timer.autostart = false
	_play_timer.process_callback = process_callback
	_play_timer.timeout.connect(_play_next)
	host.add_child(_play_timer)


# 播放下一个时间点
func _play_next():
	if _play_timer.paused:
		return
	
	_key_index_of_play += 1
	if _key_index_of_play < _key_time_to_data_map.size():
		# 这个关键帧的开始播放的时间
		var key_time = get_key_time_list()[_key_index_of_play]
		var time = get_key_time_length(_key_index_of_play)
		self.elapsed.emit(_key_index_of_play, time, _key_time_to_data_map[key_time])
		# 发出经过关键帧的信号
		_play_timer.stop()
		if time > 0:
			_play_timer.start(time)
		else:
			_play_next()
	else:
		_key_index_of_play = -1
		finished.emit()


## 播放时间线
##[br]
##[br][code]reset[/code] 是否重新开始播放。如果值为 [code]false[/code]，则暂停状态会被解
##除继续播放。如果值为 [code]true[/code]，则重新开始播放
func play(reset : bool = false):
	if not _play_timer.is_inside_tree():
		_init_play_timer(Engine.get_main_loop().current_scene)
	_play_timer.paused = false
	if not reset and _key_index_of_play != -1:
		continue_played.emit()
	else:
		_key_index_of_play = -1
		played.emit()
		if not _play_timer.paused:
			_play_next()


## 停止播放
func stop():
	var is_emit := is_playing()
	_play_timer.paused = false
	_play_timer.stop()
	_play_timer.paused = true
	_key_index_of_play = -1
	if is_emit:
		self.stopped.emit()


## 强制播放下一个
func force_play_next():
	if _key_index_of_play > -1:
		_play_next()


## 跳到时间点索引播放，如果正在暂停，则会在此继续播放
##[br]
##[br][code]idx[/code]  时间点索引号。序号从第 [code]0[/code] 个时间点位置开始播放
func goto_key(idx: int):
	_play_timer.paused = false
	_key_index_of_play = idx
	_play_next()


## 暂停播放。调用[method play]则继续播放，如果调用 [method play] 时传入参数值为 [code]true[/code]
##，则会重新进行播放
func pause():
	if not _play_timer.paused or _key_index_of_play > -1:
		_play_timer.paused = true
		self.paused.emit()

