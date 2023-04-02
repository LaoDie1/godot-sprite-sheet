#============================================================
#    Surround
#============================================================
# - datetime: 2022-09-12 12:30:26
#============================================================
##  节点环绕
class_name Surround
extends Node2D


@export
var speed = 100.0
@export
var a : Node2D
@export
var b : Node2D


var deg : float = 0.0
var distance : float = 0.0
var w : float = 0.0


func _ready() -> void:
	distance = b.position.distance_to(a.position)
	w = speed / distance


func _process(delta: float) -> void:
	deg -= w * delta
	b.position = polar_to_cartesian(distance, deg)
	b.position += a.position


func polar_to_cartesian(r:float, th: float) -> Vector2:
	return Vector2(r * cos(th), r * sin(th))


