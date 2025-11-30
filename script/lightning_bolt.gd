extends Node3D
class_name LightningBolt

@export var lifetime := 0.4
@export var segments := 10
@export var jaggedness := 0.3
@export var branch_chance := 0.3

var start_point: Vector3
var end_point: Vector3
var elapsed := 0.0

@onready var beam: MeshInstance3D = $Beam
@onready var light: OmniLight3D = $OmniLight3D
@onready var impact_light: OmniLight3D = $ImpactLight

func _ready():
	# Flash effect
	var tween = create_tween()
	tween.tween_property(light, "light_energy", 0.0, lifetime)
	tween.parallel().tween_property(impact_light, "light_energy", 0.0, lifetime)
	
	# Screen shake bisa ditambahkan di sini
	
	# Auto destroy
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _process(delta):
	elapsed += delta
	
	# Flicker lights
	var flicker = randf_range(0.7, 1.0)
	light.light_energy = 8.0 * flicker * (1.0 - elapsed / lifetime)
	impact_light.light_energy = 5.0 * flicker * (1.0 - elapsed / lifetime)

func set_points(start: Vector3, end: Vector3):
	start_point = start
	end_point = end
	
	# Position di tengah antara start dan end
	global_position = (start + end) / 2.0
	
	# Hitung panjang dan arah
	var direction = end - start
	var length = direction.length()
	
	# Rotate untuk menghadap dari start ke end
	if direction.normalized() != Vector3.UP and direction.normalized() != Vector3.DOWN:
		look_at(end, Vector3.UP)
		rotate_object_local(Vector3.RIGHT, deg_to_rad(90))
	else:
		if direction.y < 0:
			rotation.x = deg_to_rad(180)
	
	# Scale beam sesuai panjang
	beam.scale = Vector3(1.0, length, 1.0)
	
	# Posisikan light di start dan impact di end
	light.global_position = start
	impact_light.global_position = end
