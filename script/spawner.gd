extends Node3D

@export var enemy_scene_path: String = "res://scene/enemy.tscn"
@export var spawn_radius: float = 15.0
@export var max_enemies: int = 3

var enemy_scene
var timer: Timer

func _ready():
	enemy_scene = load(enemy_scene_path)
	
	timer = Timer.new()
	timer.wait_time = 3.0 # Spawn tiap 3 detik
	timer.autostart = true
	timer.timeout.connect(_on_spawn_timer)
	add_child(timer)

func _on_spawn_timer():
	if get_tree().get_nodes_in_group("enemy").size() >= max_enemies:
		return

	var player = get_tree().get_first_node_in_group("player")
	if not player: return
	
	var enemy = enemy_scene.instantiate()
	get_parent().add_child(enemy)
	
	# Random posisi lingkaran di sekitar player
	var angle = randf() * PI * 2
	var offset = Vector3(cos(angle), 0, sin(angle)) * spawn_radius
	
	enemy.global_position = player.global_position + offset
	enemy.global_position.y = 1.0 # Spawn agak di atas tanah
