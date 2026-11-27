extends Control
## Last Signal — animated main-menu backdrop (2026-11-24).
##
## A starfield (code-drawn, twinkling, three parallax layers drifting left),
## an occasional shooting star, a purple gas giant rising in the lower
## right, and a small ship hovering near it (slow sway + bob, flickering
## engine flame). Everything is positioned from `size`, so it follows the
## viewport. Textures are loaded at runtime and skipped if missing, so a
## missing/unimported file can never break the menu.

const PLANET_PATH := "res://assets/ui/menu/planet.png"
const SHIP_PATH := "res://assets/ui/menu/ship.png"
const FLAME_PATHS := ["res://assets/ui/menu/flame_0.png", "res://assets/ui/menu/flame_1.png"]
const STAR_COUNT := 130
const LAYER_SPEEDS := [3.0, 7.0, 14.0]  # px/s, far to near
const FLAME_PERIOD := 0.07

var _stars: Array = []  # {pos, layer, phase, rate}
var _time: float = 0.0
var _planet: TextureRect = null
var _ship: TextureRect = null
var _flame: TextureRect = null
var _flame_frames: Array[Texture2D] = []
var _flame_timer: float = 0.0
var _flame_index: int = 0
var _planet_base: Vector2 = Vector2.ZERO
var _ship_base: Vector2 = Vector2.ZERO
var _streak_t: float = -1.0
var _streak_from: Vector2 = Vector2.ZERO
var _streak_wait: float = 3.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var rng := RandomNumberGenerator.new()
	rng.seed = 24
	for i in STAR_COUNT:
		_stars.append({
			"pos": Vector2(rng.randf() * 640.0, rng.randf() * 360.0),
			"layer": rng.randi_range(0, 2),
			"phase": rng.randf() * TAU,
			"rate": rng.randf_range(0.6, 2.2),
		})
	_planet = _make_sprite(PLANET_PATH)
	_ship = _make_sprite(SHIP_PATH)
	for path in FLAME_PATHS:
		if ResourceLoader.exists(path):
			_flame_frames.append(load(path))
	if not _flame_frames.is_empty():
		_flame = TextureRect.new()
		_flame.texture = _flame_frames[0]
		_flame.stretch_mode = TextureRect.STRETCH_KEEP
		_flame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_flame.size = _flame_frames[0].get_size()
		add_child(_flame)
	_layout()
	resized.connect(_layout)
	# Soft fade-in so the scene doesn't pop.
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 1.0)


func _make_sprite(path: String) -> TextureRect:
	if not ResourceLoader.exists(path):
		return null
	var tex: Texture2D = load(path)
	var rect := TextureRect.new()
	rect.texture = tex
	rect.stretch_mode = TextureRect.STRETCH_KEEP
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.size = tex.get_size()
	add_child(rect)
	return rect


func _layout() -> void:
	# Planet center sits near the lower-right corner (partly off-screen);
	# the ship sits in the upper-left corner, nose pointing right toward
	# the planet, clear of the title and the buttons.
	if _planet != null:
		_planet_base = Vector2(size.x - 72.0, size.y - 34.0) - _planet.size / 2.0
		_planet.position = _planet_base.round()
	if _ship != null:
		_ship_base = Vector2(size.x * 0.13, size.y * 0.24) - _ship.size / 2.0
		_ship.position = _ship_base.round()


func _process(delta: float) -> void:
	_time += delta
	# Gas giant: barely-there vertical float.
	if _planet != null:
		_planet.position = (_planet_base + Vector2(0.0, sin(_time * 0.35) * 3.0)).round()
	# Ship: slow horizontal sway + faster bob, pixel-snapped.
	if _ship != null:
		var offset := Vector2(sin(_time * 0.5) * 24.0, sin(_time * 1.7) * 3.5)
		_ship.position = (_ship_base + offset).round()
		if _flame != null:
			_flame_timer += delta
			if _flame_timer >= FLAME_PERIOD:
				_flame_timer = 0.0
				_flame_index = (_flame_index + 1) % _flame_frames.size()
				_flame.texture = _flame_frames[_flame_index]
				_flame.size = _flame.texture.get_size()
			_flame.position = _ship.position + Vector2(-14.0, 9.0)
	# Stars drift left and wrap.
	for star in _stars:
		var p: Vector2 = star["pos"]
		p.x -= LAYER_SPEEDS[star["layer"]] * delta
		if p.x < -2.0:
			p.x += maxf(size.x, 640.0) + 4.0
		star["pos"] = p
	# Shooting star every few seconds.
	if _streak_t >= 0.0:
		_streak_t += delta
		if _streak_t > 0.7:
			_streak_t = -1.0
			_streak_wait = randf_range(4.0, 9.0)
	else:
		_streak_wait -= delta
		if _streak_wait <= 0.0:
			_streak_t = 0.0
			_streak_from = Vector2(randf_range(size.x * 0.1, size.x * 0.55), randf_range(10.0, size.y * 0.35))
	queue_redraw()


func _draw() -> void:
	for star in _stars:
		var layer: int = star["layer"]
		var twinkle := 0.55 + 0.45 * sin(_time * float(star["rate"]) + float(star["phase"]))
		var brightness := (0.35 + 0.25 * layer) * twinkle + 0.15
		var pos: Vector2 = (star["pos"] as Vector2).round()
		var color := Color(0.8, 0.82, 1.0, clampf(brightness, 0.0, 1.0))
		if layer == 2:
			draw_rect(Rect2(pos, Vector2(2, 2)), color)
		else:
			draw_rect(Rect2(pos, Vector2(1, 1)), color)
	if _streak_t >= 0.0:
		var k := _streak_t / 0.7
		var head := _streak_from + Vector2(140.0, 60.0) * k
		for i in 8:
			var tail := head - Vector2(10.0, 4.3) * i
			draw_rect(Rect2(tail.round(), Vector2(2, 1)), Color(1, 1, 1, (1.0 - i / 8.0) * (1.0 - k)))
