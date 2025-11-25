extends CharacterBody3D

@export var hp := 50
@export var move_speed := 3.0
@export var damage := 10

var is_frozen := false
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var player = get_tree().get_first_node_in_group("player") # Player juga harus masuk group "player"

func _physics_process(delta):
	if is_frozen:
		return # Diam jika beku

	if not is_on_floor():
		velocity.y -= gravity * delta

	if player:
		# Logika kejar player sederhana
		var dir = (player.global_position - global_position).normalized()
		dir.y = 0 # Jangan terbang ke atas
		velocity.x = dir.x * move_speed
		velocity.z = dir.z * move_speed
		
		# Rotasi menghadap player
		look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z))
	
	move_and_slide()

func take_damage(amount):
	hp -= amount
	# Efek visual kena hit (optional, misal ganti warna merah sebentar)
	var mesh = find_child("MeshInstance3D")
	if mesh:
		var tween = create_tween()
		tween.tween_property(mesh, "scale", Vector3(1.2, 1.2, 1.2), 0.1)
		tween.tween_property(mesh, "scale", Vector3(1.0, 1.0, 1.0), 0.1)
		
	if hp <= 0:
		die()

func apply_freeze():
	if is_frozen: return
	is_frozen = true
	
	# Ubah warna jadi biru
	var mesh = find_child("MeshInstance3D")
	if mesh:
		mesh.modulate = Color(0.5, 0.5, 1.0) 
		
	print("Enemy Frozen!")
	
	# Cair setelah 4 detik
	await get_tree().create_timer(4.0).timeout
	is_frozen = false
	if mesh: mesh.modulate = Color(1, 1, 1)

func die():
	queue_free()
