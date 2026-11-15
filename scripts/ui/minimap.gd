extends Control
## Last Signal — Minimap (v1.2, 2026-11-12).
##
## A small live map of station K-17 in the HUD's top-right corner.
## Always shows the static layout (five area tints + walls with their
## doorway gaps), the player's position, and the three towers by state
## (offline / powered / online). Hidden caches appear only once a radar
## pulse has revealed them. Enemies are NOT shown by default — stealth
## would be trivial otherwise; a radar pulse marks every enemy inside
## its radius on the map for REVEAL_DURATION seconds (the pulse is
## sound, so enemies "hear" it — the map shows what the pulse heard).
## Toggle with M (input action toggle_minimap, handled by hud.gd).
##
## The map is drawn in code (_draw); world_to_map is a pure function so
## the headless test runner can verify the mapping without rendering.

const WORLD_SIZE := Vector2(1280, 928)
const MAP_WIDTH := 208.0
const SCALE := MAP_WIDTH / WORLD_SIZE.x
const MAP_SIZE := Vector2(MAP_WIDTH, WORLD_SIZE.y * SCALE)
const REVEAL_DURATION := 6.0

const COLOR_BG := Color(0.04, 0.05, 0.08, 0.85)
const COLOR_BORDER := Color(0.5, 0.55, 0.65, 0.9)
const COLOR_WALL := Color(0.78, 0.81, 0.88)
const COLOR_PLAYER := Color(0.3, 1.0, 0.4)
const COLOR_ENEMY := Color(1.0, 0.2, 0.2)
const COLOR_TOWER_OFF := Color(0.5, 0.5, 0.55)
const COLOR_TOWER_POWERED := Color(1.0, 0.75, 0.2)
const COLOR_TOWER_ONLINE := Color(0.2, 1.0, 0.4)
const COLOR_CACHE := Color(1.0, 0.85, 0.3)

var areas: Array = []
var walls: Array[Rect2] = []
var player: Node2D = null
var towers: Array = []
var hidden_objects: Array = []
var enemies: Array = []
## enemy -> expiry time (seconds, Time.get_ticks_msec based).
var _enemy_marks: Dictionary = {}


func setup(p_areas: Array, p_walls: Array[Rect2], p_player: Node2D, p_towers: Array, p_hidden: Array, p_enemies: Array) -> void:
	areas = p_areas
	walls = p_walls
	player = p_player
	towers = p_towers
	hidden_objects = p_hidden
	enemies = p_enemies
	queue_redraw()


func world_to_map(world_pos: Vector2) -> Vector2:
	return world_pos * SCALE


func player_map_position() -> Vector2:
	if player == null:
		return Vector2.ZERO
	return world_to_map(player.global_position)


## Tower dot state: 0 = offline, 1 = powered (puzzle solved), 2 = online.
func tower_state(tower: Node) -> int:
	if tower.get("is_active") == true:
		return 2
	if tower.get("power_restored") == true:
		return 1
	return 0


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


## Mark every enemy inside the pulse radius as visible on the map.
func mark_enemies_from_pulse(origin: Vector2, radius: float) -> void:
	if radius <= 0.0:
		return
	for enemy in enemies:
		if enemy == null:
			continue
		if (enemy as Node2D).global_position.distance_to(origin) <= radius:
			_enemy_marks[enemy] = _now() + REVEAL_DURATION
	queue_redraw()


func is_enemy_revealed(enemy: Node) -> bool:
	return float(_enemy_marks.get(enemy, -1.0)) > _now()


func revealed_enemy_count() -> int:
	var count := 0
	for enemy in _enemy_marks:
		if is_enemy_revealed(enemy):
			count += 1
	return count


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), COLOR_BG)
	draw_rect(Rect2(Vector2.ZERO, size), COLOR_BORDER, false, 1.0)
	# Area tints (Central Control's tint is transparent — skip it).
	for area in areas:
		var tint: Color = area["tint"]
		if tint.a <= 0.0:
			continue
		var r: Rect2 = area["rect"]
		var map_rect := Rect2(world_to_map(r.position), r.size * SCALE)
		draw_rect(map_rect, Color(tint.r, tint.g, tint.b, 0.22))
	# Walls (doorway gaps show because walls are separate rects).
	for wall in walls:
		var map_rect := Rect2(world_to_map(wall.position), wall.size * SCALE)
		draw_rect(map_rect, COLOR_WALL)
	# Towers by state.
	for tower in towers:
		if tower == null:
			continue
		var pos := world_to_map((tower as Node2D).global_position)
		var color := COLOR_TOWER_OFF
		match tower_state(tower):
			1:
				color = COLOR_TOWER_POWERED
			2:
				color = COLOR_TOWER_ONLINE
		draw_circle(pos, 3.0, color)
		draw_arc(pos, 3.0, 0.0, TAU, 12, Color(0, 0, 0, 0.8), 1.0)
	# Hidden caches, only once revealed.
	for obj in hidden_objects:
		if obj == null or obj.get("is_revealed") != true:
			continue
		draw_circle(world_to_map((obj as Node2D).global_position), 2.0, COLOR_CACHE)
	# Enemies, only while a pulse mark is fresh.
	for enemy in enemies:
		if enemy == null or not is_enemy_revealed(enemy):
			continue
		var pos := world_to_map((enemy as Node2D).global_position)
		draw_circle(pos, 3.0, COLOR_ENEMY)
		draw_arc(pos, 3.0, 0.0, TAU, 12, Color(1, 1, 1, 0.9), 1.0)
	# Player: green dot, white ring, slow pulse.
	if player != null:
		var pos := player_map_position()
		var pulse := 5.0 + sin(Time.get_ticks_msec() / 1000.0 * 4.0) * 1.5
		draw_arc(pos, pulse, 0.0, TAU, 16, Color(0.3, 1.0, 0.4, 0.5), 1.0)
		draw_circle(pos, 3.5, COLOR_PLAYER)
		draw_arc(pos, 3.5, 0.0, TAU, 12, Color(1, 1, 1, 0.95), 1.0)
