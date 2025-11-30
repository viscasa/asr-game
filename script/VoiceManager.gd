extends Node

signal command_detected(text)

@onready var speech_to_text = $CaptureStreamToText
@onready var mic_player = $MicPlayer

var bus_layout_path = "res://samples/godot_whisper/sample_bus_layout.tres"

func _ready():
	_setup_audio_system()
	_setup_mic()
	_setup_speech_to_text()

func _setup_audio_system():
	if ResourceLoader.exists(bus_layout_path):
		if AudioServer.bus_count < 2: 
			AudioServer.set_bus_layout(load(bus_layout_path))

func _setup_mic():
	if mic_player:
		mic_player.bus = "Record"
		if not mic_player.playing:
			mic_player.play()

func _setup_speech_to_text():
	if speech_to_text:
		if not speech_to_text.transcribed_msg.is_connected(_on_transcribed_msg):
			speech_to_text.transcribed_msg.connect(_on_transcribed_msg)
		
		speech_to_text.recording = false
		
		await get_tree().create_timer(0.5).timeout
		
		speech_to_text.recording = true
		print("[VoiceManager] Audio System Ready & Listening...")

func _on_transcribed_msg(is_partial, new_text):
	var clean_text = new_text.to_lower().strip_edges()
	clean_text = clean_text.replace(".", "").replace(",", "").replace("!", "").replace("?", "")
	
	if clean_text.length() > 1:
		print("[VoiceManager] Heard: ", clean_text)
		command_detected.emit(clean_text)

func _exit_tree():
	if speech_to_text:
		speech_to_text.recording = false
