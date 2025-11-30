extends CharacterBody3D
class_name Enemy

@export var hp := 50
@export var move_speed := 3.0
@export var damage := 1
var is_swinging:bool = false
var can_attack := true
var attack_cooldown := 1.5  # Cooldown antara serangan

var is_frozen := false
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var player = get_tree().get_first_node_in_group("player")
@onready var raycast: RayCast3D = $RayCast3D
@onready var anim_player: AnimationPlayer = $AnimationPlayer

func _physics_process(delta):
	if is_frozen:
		swing_sword()
		return # Diam jika beku

	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Cek apakah raycast mendeteksi player
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider and collider.is_in_group("player"):
			attack_player()

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

var original_material: Material = null
var freeze_material: StandardMaterial3D = null

func apply_freeze():
	anim_player.play("RESET")
	if is_frozen: return
	is_frozen = true
	
	# Ubah warna jadi biru
	var mesh = $Skeleton3D/BodyAttachment/Mesh as MeshInstance3D
	if mesh:
		# Simpan material asli
		if original_material == null:
			original_material = mesh.material_override
		
		# Buat material biru untuk freeze
		if freeze_material == null:
			freeze_material = StandardMaterial3D.new()
			freeze_material.albedo_color = Color(0.3, 0.5, 1.0)  # Warna biru es
			freeze_material.emission_enabled = true
			freeze_material.emission = Color(0.2, 0.4, 0.8)
			freeze_material.emission_energy_multiplier = 0.5
		
		mesh.material_override = freeze_material
		
	print("Enemy Frozen!")
	
	# Cair setelah 4 detik
	await get_tree().create_timer(4.0).timeout
	is_frozen = false
	if mesh: 
		mesh.material_override = original_material

func die():
	queue_free()

@onready var skeleton: Skeleton3D = $Skeleton3D

func swing_sword():
	if is_swinging:
		return
	is_swinging = true
	var right_arm_idx = skeleton.find_bone("RightArm")
	# Rotasi tangan kanan
	var rotation = Quaternion.from_euler(Vector3(0, 0, deg_to_rad(-45)))
	skeleton.set_bone_pose_rotation(right_arm_idx, rotation)

func reset_arm():
	var right_arm_idx = skeleton.find_bone("RightArm")
	skeleton.set_bone_pose_rotation(right_arm_idx, Quaternion.IDENTITY)

func attack_player():
	if not can_attack or is_swinging:
		return
	
	can_attack = false
	is_swinging = true
	
	# Mainkan animasi attack
	anim_player.play("attack")
	
	await anim_player.animation_finished
	
	anim_player.play("RESET")
	
	# Cooldown sebelum bisa attack lagi
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true
	is_swinging = false

func _on_area_3d_body_entered(body: Node3D) -> void:
	# Saat Area3D (sword hitbox) mengenai player
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)
