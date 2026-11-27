extends Node
## Last Signal — Audio manager (Phase 9, ambient fix 2026-11-12).
##
## All sounds are generated procedurally in code (sine/square tones with
## frequency ramps) — there are no audio files in the project, so nothing
## here is a fake asset. Sounds are built once in _ready as AudioStreamWAV
## data and played through a small pool of players (round-robin, so
## overlapping sounds don't cut each other off).
##
## No autoload on purpose: the manager is a plain child node of the main
## scene (and of the main menu), found via group "audio" — the same
## lookup pattern the HUD uses. That keeps headless level-only tests
## working without a singleton.
##
## Ambient vs one-shots (fixed 2026-11-12): the old _build applied the
## 1.0 - t/dur decay envelope to EVERY stream, including the 2 s ambient
## drone — so the ambient faded to silence every 2 s and restarted with
## an audible jump, even though its 55 Hz / 110-cycle loop was seamless
## in phase. Now the ambient is built with a constant envelope (no decay)
## and loops seamlessly, while one-shot effects keep their attack/decay
## envelope. Ambient also has explicit pause/resume and volume control.

var streams: Dictionary = {}

var _players: Array[AudioStreamPlayer] = []
var _next_player: int = 0
var _ambient_player: AudioStreamPlayer


func _ready() -> void:
	add_to_group("audio")
	_build_streams()
	for i in 4:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_ambient_player = AudioStreamPlayer.new()
	add_child(_ambient_player)
	_ambient_player.stream = streams["ambient"]
	_ambient_player.volume_db = -24.0


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


func pause_ambient() -> void:
	if _ambient_player.playing:
		_ambient_player.stream_paused = true


func resume_ambient() -> void:
	_ambient_player.stream_paused = false
	if not _ambient_player.playing:
		_ambient_player.play()


func is_ambient_playing() -> bool:
	return _ambient_player.playing and not _ambient_player.stream_paused


func set_ambient_volume_db(db: float) -> void:
	_ambient_player.volume_db = clampf(db, -40.0, 0.0)


func has_sound(sound_name: String) -> bool:
	return streams.has(sound_name)


func _build_streams() -> void:
	# Each segment: [freq_start, freq_end, duration, volume, wave]
	# wave 0 = sine, 1 = square-ish.
	streams["click"] = _build([[1200.0, 1200.0, 0.05, 0.4, 0]])
	streams["blip"] = _build([[880.0, 1320.0, 0.09, 0.5, 0]])
	streams["pulse"] = _build([[300.0, 900.0, 0.3, 0.5, 0]])
	streams["chime"] = _build([[660.0, 660.0, 0.12, 0.5, 0], [990.0, 990.0, 0.2, 0.5, 0]])
	streams["error"] = _build([[140.0, 110.0, 0.18, 0.5, 1]])
	streams["sting"] = _build([[400.0, 90.0, 0.4, 0.5, 1]])
	streams["tower"] = _build([[440.0, 440.0, 0.1, 0.5, 0], [660.0, 660.0, 0.1, 0.5, 0], [880.0, 880.0, 0.18, 0.5, 0]])
	streams["zap"] = _build([[2200.0, 400.0, 0.08, 0.45, 1], [900.0, 1500.0, 0.06, 0.4, 1], [1800.0, 250.0, 0.12, 0.4, 1]])
	streams["fanfare"] = _build([[523.0, 523.0, 0.14, 0.5, 0], [659.0, 659.0, 0.14, 0.5, 0], [784.0, 784.0, 0.3, 0.5, 0]])
	# Ambient: constant envelope (no fade). 2.0 s at 55 Hz is exactly
	# 110 cycles at 22050 Hz, so phase AND amplitude are continuous
	# across the loop point — no fade-out, no click on restart.
	streams["ambient"] = _build([[55.0, 55.0, 2.0, 0.35, 0]], false)
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
