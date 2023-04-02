#============================================================
#    Skill Actuator
#============================================================
# - datetime: 2022-11-26 00:29:06
#============================================================
##技能执行器
##
##以控制 [TimeLine] 作为基础进行技能功能的实现。先调用 [method set_stages] 方法设置执行阶段，
##再调用 [method add_skill] 进行添加技能。
##[br]
##[br]示例：
##[codeblock]
##var skill_management = SkillActuator.new()
##add_child(skill_management)
### 设置技能执行阶段
##skill_management.set_stages(["casted", "ready", "before", "executing", "after", "cooldown"])
### 添加技能，及对应阶段的时间的数据（下面的 key 对应上面的执行阶段即为对应阶段的执行时间）
##skill_management.add_skill("skill_01", {
##    "name": "skill_01",
##    "ready": 1,
##    "before": 0.2,
##    "executing": 1.0,
##    "after": 0.1,
##    "cooldown": 2.0,
##})
##[/codeblock]
class_name SkillActuator
extends Node


## 新增技能
signal newly_added_skill(skill_name: StringName)
## 移除技能
signal removed_skill(skill_name: StringName)

## 开始执行技能
signal started(skill_name: StringName)
## 技能执行阶段发生改变
signal stage_changed(skill_name: StringName, stage_idx: int, data: Dictionary)
## 打断技能
signal interruptted(skill_name: StringName)
## 已强行停止技能
signal stopped(skill_name: StringName)
## 执行完成
signal finished(skill_name: StringName)
## 执行中止。打断、停止、执行完成都会调用这个信号
signal ended(skill_name: StringName)


enum {
	## 未执行
	UNEXECUTED = -1,
	## 技能不存在
	NON_EXISTENT = -2,
}


## 技能执行阶段。调用 [method add_skill] 时，传入的 [Dictionary] 数据中的 key 如果有这个阶段的值，
##则获取这个数据的值为播放时间数据，否则播放时间按照默认 [member TimeLine.DEFAULT_MIN_INTERVAL_TIME]
##时间计算
@export
var stages : Array : set=set_stages
## 忽略缺省的数据中的 key。如果这个属性为 true，则在添加技能数据时不再强制要求必须要有这个 key，
##缺省的值默认为 -1
@export
var ignore_default_key : bool = true


# 当前正在执行的技能
var _current_execute_skills := {}


# 技能名称对应的技能节点
var _name_to_skill_map := {}
# 技能名称对应的技能数据
var _name_to_data_map := {}
# id对应的监听的回调方法
var _id_to_listen_callable := {}


#============================================================
#  SetGet
#============================================================
# 获取技能
func _get_skill(skill_name: StringName) -> TimeLine:
	var skill = _name_to_skill_map.get(skill_name)
	if skill:
		return skill
	else:
		printerr("没有这个技能：", skill_name)
		return null


##设置技能执行几个阶段的值（按顺序），如果不设置则在 [method add_skill] 的时候添加的数据的时
##候没有执行时间
func set_stages(v: Array):
	stages = v


## 获取这个 [code]stage[/code] 索引的阶段的名称
func get_stage_name(stage_idx: int):
	if stage_idx >= 0 and stage_idx < stages.size():
		return stages[stage_idx]
	return null

## 获取正在执行的技能名称列表
func get_executing_skills() -> Array:
	return _current_execute_skills.keys()

##  是否正在执行
##[br]
##[br][code]skill_name[/code]  技能名称
##[br][code]return[/code]  返回这个技能是否正在执行
func is_executing(skill_name: StringName) -> bool:
	return _current_execute_skills.has(skill_name)

##  技能能否执行
func is_can_execute(skill_name: StringName) -> bool:
	return has_skill(skill_name) and not is_executing(skill_name)


## 添加技能。技能中需要有 [member stages] 中的 key，比如 [member stages] 属性的值为 [code]
##["ready", "before", "execute", "after"][/code]，则 [code]data[/code] 参数中至少要有
##包含以下的 key 的数据：
##[codeblock]
##{
##  "ready": 0.1,
##  "before": 0,
##  "execute": 1.0,
##  "after": 0,
##}
##[/codeblock]
##[br]用以在执行时判断这些数据的执行阶段和时间，如果设置 [member ignore_default_key] 为 
##[code]true[/code] 则可以忽略
func add_skill(skill_name: StringName, data: Dictionary):
	if not ignore_default_key:
		assert(data.has_all(stages), "stages 属性中的某些阶段值，数据中不存在这个名称的 key！")
	
	_name_to_data_map[skill_name] = data
	
	var skill := TimeLine.new()
	_name_to_skill_map[skill_name] = skill
	for stage in stages:
		var time = data.get(stage, -1)
		# 这里 push_key 的时候传入的 data 为 null，因为下面 skill.elapsed 信号已经连接
		# 到的 Callable 中发送信号的时候已经有 data 数据了，这里添加没有用到，所以是多余的。
		# 既然这样那就不添加了
		skill.push_key(null, time)
	add_child(skill)
	
	# 阶段发生改变
	skill.elapsed.connect( func(idx: int, time: float, elapsed_data):
		# 监听回调方法
		for callable in get_listen_callback_list(skill_name):
			callable.call(idx, data)
		self.stage_changed.emit( skill_name, idx, data )
	)
	
	# 执行时
	skill.played.connect(func(): 
		self._current_execute_skills[skill_name] = null
		self.started.emit(skill_name)
	)
	skill.continue_played.connect(func():
		self._current_execute_skills[skill_name] = null
	)
	
	# 执行结束
	var skill_end = func(signal_: Signal):
		self._current_execute_skills.erase(skill_name)
		signal_.emit(skill_name)
		self.ended.emit(skill_name)
	skill.finished.connect( skill_end.bind(self.finished) )
	skill.paused.connect( skill_end.bind(self.interruptted) )
	skill.stopped.connect( skill_end.bind(self.stopped) )
	
	# 新增技能
	self.newly_added_skill.emit(skill_name)


## 移除技能
func remove_skill(skill_name: StringName):
	_name_to_skill_map.erase(skill_name)
	removed_skill.emit(skill_name)


## 是否有这个技能
func has_skill(skill_name: StringName) -> bool:
	return _name_to_skill_map.has(skill_name)


## 获取技能执行到的阶段。如果没有在执行，则返回 [code]-1[/code]，如果没有这个技能，则返回
##[code]-2[/code]
func get_skill_stage(skill_name: StringName) -> int:
	var skill = _get_skill(skill_name)
	if skill:
		return skill.get_current_key_index()
	return NON_EXISTENT


## 获取这个技能的数据
func get_skill_data(skill_name: StringName):
	if has_skill(skill_name):
		return _name_to_data_map[skill_name]
	return null


## 获取这个技能执行状态的名称
func get_skill_stage_name(skill_name: StringName) -> String:
	if has_skill(skill_name):
		var stage = get_skill_stage(skill_name)
		return get_stage_name(stage)
	return ""

## 这个技能当前是否正在这个阶段中运行
func is_in_stage(skill_name: StringName, stage_idx: int) -> bool:
	var skill = _get_skill(skill_name)
	if skill:
		return skill.get_current_key_index() == stage_idx
	return false


var _skill_monitor_callback_map : Dictionary = {}
## 获取监听技能的回调方法列表
func get_listen_callback_list(skill_name: StringName) -> Array:
	if _skill_monitor_callback_map.has(skill_name):
		return _skill_monitor_callback_map[skill_name]
	else:
		_skill_monitor_callback_map[skill_name] = []
		return _skill_monitor_callback_map[skill_name]


## 监听技能执行阶段。
##[br]
##[br][code]skill_name[/code]  监听的技能名称
##[br][code]callable[/code]  回调方法。这个方法需要有两个参数，一个 stage_idx 用于接收执行阶段的值，一个 
##skill_data 用于接收行的技能的数据
##[br][code]return[/code]  返回连接的id，这个id用于断开监听连接
func listen_skill(skill_name: StringName, callable: Callable) -> String:
	var id = [hash(skill_name), hash(callable)]
	get_listen_callback_list(skill_name).append(callable)
	_id_to_listen_callable[id] = {
		"skill": skill_name,
		"callable": callable,
	}
	return id


##  断开监听技能
##[br]
##[br][code]id[/code]  监听ID
func disconnect_listen(id) -> bool:
	var data = _id_to_listen_callable.get(id, {}) as Dictionary
	if data:
		var skill_name = data["skill"]
		var callable = data["callable"]
		var list = get_listen_callback_list(skill_name)
		list.erase(callable)
		return true
	return false



#============================================================
#  自定义
#============================================================
## 执行技能
##[br]
##[br][code]skill_name[/code]  技能名称
##[br][code]additional[/code]  附加数据。如果技能数据中包含有这个数据，则会被覆盖，相当于
##修改技能的数据
func execute(skill_name: StringName, additional: Dictionary = {}):
	assert(not stages.is_empty(), "没有设置执行阶段的值！")
	var skill = _get_skill(skill_name)
	if skill:
		var data = get_skill_data(skill_name)
		if data is Dictionary:
			data.merge(additional, true)
		# 从头开始播放
		skill.play(true)


## 继续执行技能
func continue_execute(skill_name: StringName):
	var skill = _get_skill(skill_name)
	if skill and is_executing(skill_name):
		skill.play(false)


## 打断技能，中止技能的执行，可以继续执行
func interrupt(skill_name: StringName):
	var skill = _get_skill(skill_name)
	if skill:
		skill.pause()


## 停止技能
func stop(skill_name: StringName):
	var skill = _get_skill(skill_name)
	if skill:
		skill.stop()


## 跳到某个阶段执行
func goto_stage(skill_name:StringName, stage_idx: int) -> void:
	var skill = _get_skill(skill_name)
	if skill and skill.is_playing():
		skill.goto_key(stage_idx)

