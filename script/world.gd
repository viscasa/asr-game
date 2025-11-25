extends Node3D

@onready var menu: CanvasLayer = $Menu
@onready var label: Label = $UI/Label

func _ready() -> void:
	menu.hide()
	VoiceManager.command_detected.connect(_on_voice_command_received)

func _on_voice_command_received(command: String) -> void:
	command = command.lstrip(" ")
	if command.begins_with("dan") :
		return
	label.text = command
	
	if "buka" in command and "menu" in command:
		menu.show()
	elif "tutup" in command and "menu" in command:
		menu.hide()
	
	if menu.visible :
		if "keluar" in command :
			get_tree().quit()
