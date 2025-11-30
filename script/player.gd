# ProtoController v1.0 by Brackeys (Modified for Mage Gameplay)
extends CharacterBody3D
class_name Player

# --- BRACKEYS MOVEMENT VARIABLES ---
@export var can_move : bool = true
@export var has_gravity : bool = true
@export var can_jump : bool = true
@export var can_sprint : bool = true
@export var can_freefly : bool = false

@export_group("Speeds")
@export var look_speed : float = 0.002
@export var base_speed : float = 7.0
@export var jump_velocity : float = 4.5
@export var sprint_speed : float = 10.0
@export var freefly_speed : float = 25.0

@export_group("Input Actions")
@export var input_left : String = "ui_left"
@export var input_right : String = "ui_right"
@export var input_forward : String = "ui_up"
@export var input_back : String = "ui_down"
@export var input_jump : String = "ui_accept"
@export var input_sprint : String = "sprint"
@export var input_freefly : String = "freefly"

# --- MAGIC SETUP ---
@export_group("Magic Setup")
@export var fireball_scene_path : String = "res://scene/fireball.tscn"
@export var lightning_scene_path : String = "res://scene/lightning_bolt.tscn"
@export var wind_ring_scene_path : String = "res://scene/wind_ring.tscn"

# (Hapus variable speech_to_text & mic_player dari sini)
var fireball_scene 
var lightning_scene 
var wind_ring_scene 

# --- INTERNAL STATE ---
var mouse_captured : bool = false
var look_rotation : Vector2
var move_speed : float = 0.0
var freeflying : bool = false
var health := 100
var max_health := 100

signal health_changed(new_health: int, max_health: int)

@onready var head: Node3D = $Head
@onready var collider: CollisionShape3D = $Collider

func _ready() -> void:
	# 1. Setup Movement
	check_input_mappings()
	look_rotation.y = rotation.y
	look_rotation.x = head.rotation.x
	
	# 2. Setup Magic Resource
	if fireball_scene_path != "":
		if ResourceLoader.exists(fireball_scene_path):
			fireball_scene = load(fireball_scene_path)
	
	if lightning_scene_path != "":
		if ResourceLoader.exists(lightning_scene_path):
			lightning_scene = load(lightning_scene_path)
	
	if wind_ring_scene_path != "":
		if ResourceLoader.exists(wind_ring_scene_path):
			wind_ring_scene = load(wind_ring_scene_path)
	
	# 3. CONNECT KE GLOBAL VOICE MANAGER
	# Player tidak perlu setup mic, cukup dengar sinyal
	# Pastikan VoiceManager sudah ada di Autoload!
	if has_node("/root/VoiceManager"):
		VoiceManager.command_detected.connect(_on_voice_command_received)
	else:
		printerr("VoiceManager Autoload tidak ditemukan! Pastikan sudah diset di Project Settings.")

	# Setup awal mouse
	capture_mouse()

func _exit_tree():
	pass # Tidak perlu stop recording manual lagi, sudah diurus Global

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		capture_mouse()
	if Input.is_key_pressed(KEY_ESCAPE):
		release_mouse()
	
	if mouse_captured and event is InputEventMouseMotion:
		rotate_look(event.relative)
	
	if can_freefly and Input.is_action_just_pressed(input_freefly):
		if not freeflying: enable_freefly()
		else: disable_freefly()

func _physics_process(delta: float) -> void:
	# Logic movement tetap sama
	if can_freefly and freeflying:
		var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
		var motion := (head.global_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		motion *= freefly_speed * delta
		move_and_collide(motion)
		return
	
	if has_gravity and not is_on_floor():
		velocity += get_gravity() * delta

	if can_jump and Input.is_action_just_pressed(input_jump) and is_on_floor():
		velocity.y = jump_velocity

	if can_sprint and Input.is_action_pressed(input_sprint):
		move_speed = sprint_speed
	else:
		move_speed = base_speed

	if can_move:
		var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
		var move_dir := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if move_dir:
			velocity.x = move_dir.x * move_speed
			velocity.z = move_dir.z * move_speed
		else:
			velocity.x = move_toward(velocity.x, 0, move_speed)
			velocity.z = move_toward(velocity.z, 0, move_speed)
	else:
		velocity.x = 0
		velocity.z = 0
	
	move_and_slide()

# --- MAGIC LOGIC (Receiver) ---

# Fungsi ini dipanggil otomatis saat VoiceManager mendeteksi kata
func _on_voice_command_received(command: String):
	# Kita terima command yang sudah bersih ("bola api", "petir", dll)
	
	# Gunakan 'match' atau 'if'
	if "bola api" in command or "api" in command:
		cast_fireball()
	elif "petir" in command:
		cast_lightning()
	elif "beku" in command or "es" in command:
		cast_freeze()
	elif "mundur" in command or "angin" in command:
		cast_pushback()
	elif "sembuh" in command or "darah" in command:
		cast_heal()

func cast_fireball():
	if not fireball_scene: 
		return
	var ball = fireball_scene.instantiate()
	get_parent().add_child(ball)
	ball.global_transform = head.global_transform
	# Offset sedikit agar tidak spawn di dalam kepala
	ball.global_position += head.global_transform.basis.z * -1.5 

func cast_lightning():
	# Ambil semua enemy
	var enemies = get_tree().get_nodes_in_group("enemy")
	
	if enemies.is_empty():
		print("Tidak ada enemy!")
		return
	
	# Pilih enemy random
	var target_enemy = enemies[randi() % enemies.size()]
	var hit_point = target_enemy.global_position + Vector3(0, 1.0, 0)  # Sedikit di atas kaki enemy
	
	# Spawn lightning dari atas enemy
	if lightning_scene:
		var sky_offset = 15.0  # Tinggi petir dari atas
		var sky_point = hit_point + Vector3(0, sky_offset, 0)
		
		# Petir utama
		var bolt = lightning_scene.instantiate()
		get_parent().add_child(bolt)
		bolt.set_points(sky_point, hit_point)
		
		# Spawn beberapa bolt untuk efek lebih dramatis
		for i in range(2):
			await get_tree().create_timer(0.05).timeout
			var extra_bolt = lightning_scene.instantiate()
			get_parent().add_child(extra_bolt)
			# Sedikit offset untuk variasi
			var offset = Vector3(randf_range(-0.3, 0.3), 0, randf_range(-0.3, 0.3))
			extra_bolt.set_points(sky_point + offset, hit_point + offset)
	
	# Damage enemy
	if target_enemy.has_method("take_damage"):
		target_enemy.take_damage(100)

func cast_freeze():
	get_tree().call_group("enemy", "apply_freeze")

func cast_pushback():
	# Spawn wind ring effect
	if wind_ring_scene:
		var ring = wind_ring_scene.instantiate()
		get_parent().add_child(ring)
		ring.global_position = global_position
		ring.global_position.y = 0.5  # Sedikit di atas lantai
	
	# Pushback semua enemy dalam radius
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if global_position.distance_to(enemy.global_position) < 20:
			var dir = (enemy.global_position - global_position).normalized()
			if "velocity" in enemy:
				enemy.velocity += dir * 200
				enemy.move_and_slide()

func cast_heal():
	health = min(health + 20, max_health)
	health_changed.emit(health, max_health)
	print("Heal casted! Health: ", health)

func take_damage(amount: int):
	health -= amount
	health = max(health, 0)
	health_changed.emit(health, max_health)
	print("Player took damage! Health: ", health)
	
	if health <= 0:
		die()

func die():
	print("Player died!")
	# Tambahkan logic game over di sini

# --- HELPER FUNCTIONS ---

func rotate_look(rot_input : Vector2):
	look_rotation.x -= rot_input.y * look_speed
	look_rotation.x = clamp(look_rotation.x, deg_to_rad(-85), deg_to_rad(85))
	look_rotation.y -= rot_input.x * look_speed
	transform.basis = Basis()
	rotate_y(look_rotation.y)
	head.transform.basis = Basis()
	head.rotate_x(look_rotation.x)

func enable_freefly():
	collider.disabled = true
	freeflying = true
	velocity = Vector3.ZERO

func disable_freefly():
	collider.disabled = false
	freeflying = false

func capture_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true

func release_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false

func check_input_mappings():
	pass
