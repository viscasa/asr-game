extends Node3D
class_name WindRing

@export var expand_duration := 0.5
@export var start_scale := 0.1
@export var end_scale := 25.0
@export var start_alpha := 0.7
@export var end_alpha := 0.0

@onready var ring_mesh: MeshInstance3D = $RingMesh

func _ready():
	# Set initial scale
	scale = Vector3(start_scale, 1.0, start_scale)
	
	# PENTING: Duplicate material agar setiap instance punya material sendiri
	var original_mat = ring_mesh.mesh.surface_get_material(0)
	if original_mat:
		var mat = original_mat.duplicate() as ShaderMaterial
		ring_mesh.set_surface_override_material(0, mat)
		
		# Reset alpha ke awal
		var wind_color = mat.get_shader_parameter("wind_color")
		if wind_color:
			mat.set_shader_parameter("wind_color", Color(wind_color.r, wind_color.g, wind_color.b, start_alpha))
		
		# Animate expansion
		var tween = create_tween()
		tween.set_parallel(true)
		
		# Scale dari kecil ke besar
		tween.tween_property(self, "scale", Vector3(end_scale, 1.0, end_scale), expand_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		
		# Fade out
		var end_color = Color(wind_color.r, wind_color.g, wind_color.b, end_alpha)
		tween.tween_property(mat, "shader_parameter/wind_color", end_color, expand_duration)
		
		# Auto destroy
		tween.chain().tween_callback(queue_free)
	else:
		# Fallback jika tidak ada material
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector3(end_scale, 1.0, end_scale), expand_duration)
		tween.tween_callback(queue_free)
