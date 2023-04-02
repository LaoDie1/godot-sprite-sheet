#============================================================
#    Pendulum
#============================================================
# - datetime: 2022-09-14 23:24:28
#============================================================
## 执行这个时会在 [member duration] 持续时间内直返回 [member RUNNING]，有 [member FAILED]
## 失败任务则终止。执行完成后 [member interval] 时间后可以再次执行。
@tool
@icon("../../icon/FTimer.png")
class_name BTPendulum
extends BaseDecorator


signal finished


## 执行持续时间
@export_range(0.001, 100, 0.001, "or_greater")
var duration : float = 1.0
## 可以再次执行的时间间隔
@export_range(0.001, 100, 0.001, "or_greater")
var interval : float = 0.001
## 如果有包含执行失败，则重新计时间隔执行时间
@export
var failed_reset : bool = true


var _duration_timer : Timer = Timer.new()
var _interval_timer : Timer = Timer.new()


var result 



func _ready():
	if not Engine.is_editor_hint():
		_duration_timer.wait_time = duration
		_duration_timer.one_shot = true
		_duration_timer.autostart = false
		self.add_child(_duration_timer)
		
		_interval_timer.wait_time = interval
		_interval_timer.one_shot = true
		_interval_timer.autostart = false
		self.add_child(_interval_timer)
		
		_duration_timer.timeout.connect(func():
			# 持续结束则开始间隔倒计时
			self._duration_timer.stop()
			self._interval_timer.start(self.interval)
			self.finished.emit()
		)


#(override)
func _task():
	# 没有正在执行时开始执行
	if _interval_timer.time_left == 0 and _duration_timer.time_left == 0:
		_duration_timer.start(duration)
	
	# 在持续时间内时
	if _duration_timer.time_left > 0:
		# 执行子节点
		result = get_child(0)._task()
		if result == FAILED:
			_duration_timer.stop()
			if failed_reset:
				_interval_timer.stop()
			return FAILED
		return RUNNING
	else:
		return FAILED
	
	return SUCCEED


## 重置间隔倒计时时间
func reset(_interval: float = 0):
	if _interval > 0:
		_duration_timer.stop()
		_interval_timer.start(_interval)
	else:
		_interval_timer.stop()
		_duration_timer.stop()

