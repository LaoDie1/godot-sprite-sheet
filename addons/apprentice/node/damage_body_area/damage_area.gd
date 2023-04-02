#============================================================
#    Damage Area
#============================================================
# - datetime: 2022-09-30 00:58:36
#============================================================
## 处理伤害内容
class_name DamageArea
extends Area2D


## 检测到节点
##[br][code]body[/code]  检测到的对象
##[br][code]collision_shape[/code]  检测到这个对象的碰撞形状，类型是 [CollisionShape2D]
##或 [CollisionPolygon2D] 
signal detected_node(body: Node2D, collision_shape: Node2D)



## 节点宿主，用于 [BodyArea] 获取这个数据
@export
var host : Node 
## 是否关闭碰撞
@export
var disabled : bool = false:
	set(v):
		if disabled != v:
			disabled = v
			if not self.is_inside_tree(): await self.ready
			for child in get_children():
				if child is CollisionShape2D or child is CollisionPolygon2D:
					child.set_deferred("disabled", disabled)


var _exception : Array = []


#============================================================
#  内置
#============================================================
func _ready() -> void:
	await get_tree().process_frame
	assert(host != null, "%s %s DamageArea 没有设置 host 属性" % [owner, get_parent()])
	self.disabled = disabled
	
	# 检测到节点
	var shape_entered = func(rid: RID, node: Node2D, shape_index: int, local_shape_index: int):
		if not node in _exception:
			var owner_id = self.shape_find_owner( local_shape_index)
			var collection = self.shape_owner_get_owner(owner_id)
			detected_node.emit(node, collection)
	self.area_shape_entered.connect(shape_entered)
	self.body_shape_entered.connect(shape_entered)
	
#	var shape_exited = func(rid: RID, node: Node2D, shape_index: int, local_shape_index: int):
#		if not _exception.has(node):
#			var owner_id = self.shape_find_owner( local_shape_index)
#			var collection = self.shape_owner_get_owner(owner_id)
#	self.area_shape_exited.connect(shape_exited)
#	self.body_shape_exited.connect(shape_exited)


#============================================================
#  自定义
#============================================================
##  添加排除检测的对象
func add_exception(node: Node2D):
	_exception.append(node)


## 开启一次
##[br]
##[br][code]time[/code]  持续时间，到达这个时间则关闭碰撞。如果小于0，则默认开始一帧的时间
func enable_once(time: float = 0.0):
	disabled = false
	if time <= 0:
		await get_tree().process_frame
		await get_tree().process_frame
		disabled = true
	else:
		await get_tree().create_timer(time).timeout
		disabled = true

