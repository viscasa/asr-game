extends Area3D

@export var speed := 20.0
@export var damage := 25
@export var life_time := 5.0

func _ready():
	await get_tree().create_timer(life_time).timeout
	queue_free()
	
func _process(delta):
	position -= transform.basis.z * speed * delta

func _on_body_entered(body):
	print("masuk", body)
	if body.is_in_group("enemy"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
	elif not body.is_in_group("player"):
		queue_free()
