extends CanvasLayer
## Last Signal — HUD (Phase 3).
##
## Two labels: an interaction prompt (bottom center, shown by the player
## when an interactable is near) and a transient message (top center,
## shown by the level when an interactable is used, hidden after 3 s).
## The HUD knows nothing about interactables; it only shows text.

@onready var prompt_label: Label = $PromptLabel
@onready var message_label: Label = $MessageLabel
@onready var radar_label: Label = $RadarLabel
@onready var puzzles_label: Label = $PuzzlesLabel
@onready var objective_label: Label = $ObjectiveLabel
@onready var battery_bar: ProgressBar = $BatteryBar
@onready var inventory_label: Label = $InventoryLabel
@onready var message_timer: Timer = $MessageTimer
@onready var flash_rect: ColorRect = $FlashRect
@onready var minimap: Control = $Minimap
@onready var minimap_label: Label = $MinimapLabel
@onready var minimap_legend: Label = $MinimapLegend
@onready var hint_label: Label = $HintLabel
@onready var hint_timer: Timer = $HintTimer

var _flash_tween: Tween
## Standing guide (mission stage). An area hint overrides it for a few
## seconds, then the timer brings this back (see show_area_hint).
var _stage_hint: String = ""


func show_prompt(text: String) -> void:
	prompt_label.text = text
	prompt_label.visible = true


func hide_prompt() -> void:
	prompt_label.visible = false


func show_message(text: String) -> void:
	message_label.text = text
	message_label.visible = true
	message_timer.start()


func set_radar_status(text: String) -> void:
	radar_label.text = text


func set_puzzles_solved(solved: int, total: int) -> void:
	puzzles_label.text = "پازل‌های حل‌شده: %d/%d" % [solved, total]


func set_objective(text: String) -> void:
	objective_label.text = text


## Contextual guide (Persian update 2026-11-12): the bottom hint line
## tells the player which key to press next. The stage hint is the
## standing text; show_area_hint overrides it briefly on entering a
## new area, then the timer restores the stage hint.
func set_stage_hint(text: String) -> void:
	_stage_hint = text
	hint_timer.stop()
	_show_hint(text)


func show_area_hint(text: String) -> void:
	_show_hint(text)
	hint_timer.start()


func clear_hint() -> void:
	_stage_hint = ""
	hint_timer.stop()
	_show_hint("")


func _show_hint(text: String) -> void:
	hint_label.text = text
	hint_label.visible = text != ""


func _on_hint_timer_timeout() -> void:
	_show_hint(_stage_hint)


var _last_battery_step: int = -1


func set_battery(value: float, maximum: float) -> void:
	# Phase 10 micro-opt: the player calls this every physics frame and
	# the battery drains continuously, so the value changes by ~0.008 per
	# frame. The bar is ~100 px wide, so updating it in 0.1-unit steps
	# (5x/second instead of 60x/second) is visually identical and skips
	# the redundant ProgressBar redraws.
	var step := int(roundf(value * 10.0))
	if step == _last_battery_step:
		return
	_last_battery_step = step
	battery_bar.max_value = maximum
	battery_bar.value = value
	# Phase 9: the bar turns red while the battery is low.
	battery_bar.modulate = Color(0.9, 0.25, 0.25) if value <= 25.0 else Color.WHITE


func flash(color: Color) -> void:
	# Phase 9: full-screen flash (red when caught, green on mission
	# complete). A previous flash is killed so rapid flashes don't fight.
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	flash_rect.color = color
	flash_rect.modulate.a = 0.45
	_flash_tween = create_tween()
	_flash_tween.tween_property(flash_rect, "modulate:a", 0.0, 0.5)


func set_inventory_text(text: String) -> void:
	inventory_label.text = text


# Minimap (v1.2): the level feeds the static layout + live node refs once
# (deferred — see level_01._setup_minimap). All three are null-safe in
# level-only tests, where there is no HUD at all.
func setup_minimap(areas: Array, walls: Array[Rect2], player_node: Node2D, tower_nodes: Array, hidden_nodes: Array, enemy_nodes: Array) -> void:
	minimap.setup(areas, walls, player_node, tower_nodes, hidden_nodes, enemy_nodes)


func set_minimap_area(area_name: String) -> void:
	minimap_label.text = area_name


func mark_minimap_enemies(origin: Vector2, radius: float) -> void:
	minimap.mark_enemies_from_pulse(origin, radius)


func toggle_minimap() -> void:
	var show := not minimap.visible
	minimap.visible = show
	minimap_label.visible = show
	minimap_legend.visible = show


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_minimap"):
		toggle_minimap()


func _on_message_timer_timeout() -> void:
	message_label.visible = false
