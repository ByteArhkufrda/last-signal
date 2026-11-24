class_name OpeningAudio
extends Node
## Last Signal — opening sequence: procedural sound, no audio files.
##
## Same pattern as scripts/audio/audio_manager.gd (sine/square tones
## built into AudioStreamWAV data, a small round-robin player pool, one
## looping ambient player), but with the opening's own set of sounds:
## low spaceship hum, electrical buzz, alarm blip, manual open/close,
## wire-rotation tick, connection zap and the power-up sweep. The shared
## AudioManager is not modified; this node lives only in the opening
## scene. Headless runs use the Dummy audio driver, so playback calls
## are safe there (nothing can be heard in this VM).

var streams: Dictionary = {}

var _players: Array[AudioStreamPlayer] = []
var _next_player: int = 0
var _ambient_player: AudioStreamPlayer


func _ready() -> void:
	add_to_group("opening_audio")
	_build_streams()
	for i in 4:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_ambient_player = AudioStreamPlayer.new()
	add_child(_ambient_player)
	_ambient_player.stream = streams["ambient"]
	_ambient_player.volume_db = -26.0


func play(sound_name: String) -> void:
	var stream: AudioStreamWAV = streams.get(sound_name)
	if stream == null:
		return
	var p := _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	p.stream = stream
	p.play()


func start_ambient() -> void:
	_ambient_player.stream_paused = false
	if not _ambient_player.playing:
		_ambient_player.play()


func stop_ambient() -> void:
	_ambient_player.stop()


func has_sound(sound_name: String) -> bool:
	return streams.has(sound_name)


func _build_streams() -> void:
	# Each segment: [freq_start, freq_end, duration, volume, wave]
	# wave 0 = sine, 1 = square-ish.
	streams["click"] = _build([[1200.0, 1200.0, 0.05, 0.4, 0]])
	streams["alarm"] = _build([[880.0, 880.0, 0.12, 0.4, 0], [660.0, 660.0, 0.12, 0.4, 0]])
	streams["buzz"] = _build([[120.0, 118.0, 0.4, 0.3, 1]])
	streams["manual_open"] = _build([[300.0, 900.0, 0.18, 0.4, 0]])
	streams["manual_close"] = _build([[900.0, 300.0, 0.15, 0.4, 0]])
	streams["rotate"] = _build([[1400.0, 1400.0, 0.04, 0.5, 0]])
	streams["connect"] = _build([[200.0, 1800.0, 0.12, 0.5, 1]])
	streams["power_up"] = _build([[180.0, 1400.0, 0.9, 0.5, 0]])
	# Ambient: constant envelope (no fade). 2.0 s at 55 Hz is exactly
	# 110 cycles at 22050 Hz, so phase AND amplitude are continuous
	# across the loop point — no fade-out, no click on restart.
	streams["ambient"] = _build([[55.0, 55.0, 2.0, 0.3, 0]], false)
	var ambient: AudioStreamWAV = streams["ambient"]
	ambient.loop_mode = AudioStreamWAV.LOOP_FORWARD
	ambient.loop_begin = 0
	ambient.loop_end = 44100


## apply_envelope=false is ONLY for the looping ambient: one-shots keep
## their decay envelope so they end cleanly instead of clicking off.
func _build(segments: Array, apply_envelope: bool = true) -> AudioStreamWAV:
	var rate := 22050
	var data := PackedByteArray()
	for seg in segments:
		var f0: float = seg[0]
		var f1: float = seg[1]
		var dur: float = seg[2]
		var vol: float = seg[3]
		var wave: int = seg[4]
		var frames := int(rate * dur)
		var start := data.size()
		data.resize(start + frames * 2)
		var phase := 0.0
		for i in frames:
			var t := float(i) / rate
			var f := lerpf(f0, f1, t / dur)
			phase += TAU * f / rate
			var s := sin(phase)
			if wave == 1:
				s = signf(s) * 0.6
			var env := 1.0 - t / dur if apply_envelope else 1.0
			var v := int(clampf(s * vol * env, -1.0, 1.0) * 32767.0)
			data.encode_s16(start + i * 2, v)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = data
	return stream
