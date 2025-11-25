extends Node

# Signal global yang akan dikirim ke seluruh game jika ada perintah suara
signal command_detected(text)

# Node references (Pastikan nama node di scene SAMA dengan ini)
@onready var speech_to_text = $CaptureStreamToText
@onready var mic_player = $MicPlayer

# Setup variables
var bus_layout_path = "res://samples/godot_whisper/sample_bus_layout.tres"

func _ready():
	_setup_audio_system()
	_setup_mic()
	_setup_speech_to_text()

func _setup_audio_system():
	# 1. Load Audio Bus Layout
	if ResourceLoader.exists(bus_layout_path):
		# Cek apakah layout perlu di-load (misal bus 'Record' belum ada)
		if AudioServer.bus_count < 2: 
			AudioServer.set_bus_layout(load(bus_layout_path))

func _setup_mic():
	# 2. Setup Mic Player
	if mic_player:
		mic_player.bus = "Record"
		if not mic_player.playing:
			mic_player.play()

func _setup_speech_to_text():
	# 3. Setup Transcriber
	if speech_to_text:
		# Connect signal dari script CaptureStreamToText
		if not speech_to_text.transcribed_msg.is_connected(_on_transcribed_msg):
			speech_to_text.transcribed_msg.connect(_on_transcribed_msg)
		
		# Reset recording state untuk memastikan thread berjalan bersih
		speech_to_text.recording = false
		
		# Tunggu sebentar untuk sinkronisasi AudioServer
		await get_tree().create_timer(0.5).timeout
		
		speech_to_text.recording = true
		print("[VoiceManager] Audio System Ready & Listening...")

func _on_transcribed_msg(is_partial, new_text):
	# LOGIC CLEANING TEXT PINDAH KE SINI
	# Agar Player menerima data yang sudah bersih
	var clean_text = new_text.to_lower().strip_edges()
	clean_text = clean_text.replace(".", "").replace(",", "").replace("!", "").replace("?", "")
	
	# Filter: Jangan kirim jika teks kosong/sampah
	if clean_text.length() > 1:
		print("[VoiceManager] Heard: ", clean_text)
		# Broadcast signal ke seluruh game (Player akan mendengarkan ini)
		command_detected.emit(clean_text)

func _exit_tree():
	if speech_to_text:
		speech_to_text.recording = false
