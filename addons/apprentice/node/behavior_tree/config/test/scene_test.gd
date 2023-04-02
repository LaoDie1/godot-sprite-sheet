#============================================================
#    Scene Test
#============================================================
# - datetime: 2023-02-08 00:44:01
#============================================================
extends BaseDoNode


@onready var player: Sprite2D = $player
@onready var area_2d: Area2D = $player/Area2D
@onready var move_controller: Node2D = $player/MoveController


class HasEnemy:
	extends BaseDoNode
	
	var area_2d: Area2D
	
	func _init(area_2d: Area2D) -> void:
		self.area_2d = area_2d
		var entered = func(node: Node):
			if node.is_in_group("enemy_test"):
				root.set_property("enemy", node)
		var exited = func(node: Node):
			if node.is_in_group("enemy_test"):
				root.set_property("enemy", null)
		area_2d.area_entered.connect(entered)
		area_2d.area_exited.connect(exited)
		area_2d.body_entered.connect(entered)
		area_2d.body_exited.connect(exited)
	
	func do() -> bool:
		return root.get_property("enemy") != null
	


var target : Node2D

func move_to_player():
	var enemy = root.get_property("enemy") as Node2D
	if enemy:
		var dir = MathUtil.N.direction_to(target, enemy)
		move_controller.move_direction( dir * root.get_delta_time() )
	

func linger():
	var enemy := root.get_property("enemy") as Node2D
	var host_pos = root.get_property("host").global_position
	var target_pos : Vector2
	if enemy:
		target_pos = enemy.global_position
	else:
		target_pos = root.get_property("linger_target_pos", Vector2.INF)
		if (target_pos == Vector2.INF 
			or MathUtil.is_in_distance(target_pos, host_pos, 20)
		):
			target_pos = MathUtil.random_vector2(host_pos).random_position(50, 150)
	
	root.set_property("linger_target_pos", target_pos)
	
	var dir = host_pos.direction_to(target_pos)
	move_controller.move_direction(dir * root.get_delta_time())



#============================================================
#  内置
#============================================================
func _ready() -> void:
	while move_controller == null:
		await get_tree().process_frame
	move_controller.moved.connect(func(vector): 
		player.position += vector 
	)
	
	var config = {
		"token": {
			"mean": [
				{ "name": "T", "type": BTPendulum,
					"init_prop": { "duration": 2, "interval": 2, },
				}
			]
		},
		"objects": {
			"readable_name": true,
			"do_method": [
				{ "name": "存在敌人", "method": HasEnemy.new(area_2d).do, },
				{ "name": "移动到位置", "method": self.move_to_player, 
					"init_prop":{
						"target": player,
						"move_controller": move_controller,
					},
					"context": func(context: Dictionary):
						var node = context["node"]
						
						JsonUtil.print_stringify(context, "\t")
						,
				},
				{ "name": "徘徊", "method": self.linger, },
			],
		}
	}
	
	var document = Document.parse_by_path(
		FileUtil.get_relative_file_by_object_path(self, "doc/document.txt"), 
		self, config, func(document: String):
			return document.replace("\t", "    ").strip_edges()
	)
	
	var root = document.root as BTNodeUtil.ROOT
	root.set_property("host", player)
	


func _input(event: InputEvent) -> void:
	if InputUtil.is_click_left(event) or InputUtil.is_motion(event):
		$StaticBody2D.global_position = InputUtil.get_global_position()
	
