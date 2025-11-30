extends Node3D

@onready var menu: CanvasLayer = $Menu
@onready var label: Label = $UI/Label
@onready var health_bar: ProgressBar = $UI/ProgressBar
@onready var player: Player = $ProtoController

func _ready() -> void:
	menu.hide()
	VoiceManager.command_detected.connect(_on_voice_command_received)
	
	# Connect player health signal
	if player:
		player.health_changed.connect(_on_player_health_changed)
		# Set initial health bar value
		health_bar.max_value = player.max_health
		health_bar.value = player.health

func _on_player_health_changed(new_health: int, max_health: int) -> void:
	health_bar.max_value = max_health
	health_bar.value = new_health

func _on_voice_command_received(command: String) -> void:
	command = command.lstrip(" ")
	if command.begins_with("dan") :
		return
	label.text = command
	
	if "buka" in command and "menu" in command:
		menu.show()
	if "tutup" in command and "menu" in command:
		menu.hide()
	
	if menu.visible :
		if "keluar" in command :
			get_tree().quit()
