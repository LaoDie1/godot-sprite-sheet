#============================================================
#    Body Area
#============================================================
# - datetime: 2022-09-30 00:58:58
#============================================================
##身体区域。用于接收 [DamageArea] 类型区域造成的伤害数据，通过调用 [method set_hurt_callback]
##方法处理受伤逻辑，造成伤害时，[DamageArea] 会自动调用这个属性回调。
class_name BodyArea
extends Area2D


## 受到伤害信号
signal got_hurt(data)


## 设置宿主，用于 [DamageArea] 获取这个数据
@export
var host : Node = null : set=set_host
## 是否关闭碰撞
@export
var disabled : bool = false:
	set(v):
		if disabled != v:
			disabled = v
			if not self.is_inside_tree():
				await self.tree_entered
			for child in get_children():
				if child is CollisionShape2D or child is CollisionPolygon2D:
					child.set_deferred("disabled", disabled)

# 受到伤害回调（对角色造成伤害时调用这个方法，这个方法需要有一个参数接收伤害数据）
var _get_hurt_callback: Callable : set = set_hurt_callback


#============================================================
#  SetGet
#============================================================
## 设置受伤回调，这个方法需要有一个参数接收 [DamageArea] 发来的伤害数据
func set_hurt_callback(callback: Callable):
	_get_hurt_callback = callback


## 设置宿主
func set_host(v: Node):
	host = v


#============================================================
#  内置
#============================================================
func _ready() -> void:
	assert(host != null, "BodyArea 没有设置 host 属性")
	self.disabled = disabled


#============================================================
#  自定义
#============================================================
## 造成伤害
func take_damage(data):
	if not _get_hurt_callback.is_null():
		_get_hurt_callback.call(data)
	got_hurt.emit(data)

