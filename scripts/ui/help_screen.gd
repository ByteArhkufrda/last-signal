extends Control
## Last Signal — Help screen (Persian update 2026-11-12).
##
## A reusable overlay: the main menu and the pause menu both instance
## this scene (hidden) and show it from their Help button. All text is
## Persian and lives in the consts below (assigned in _ready) so the
## .tscn stays free of multi-line strings. The goal section says what
## to do to finish the game; the controls section says which key does
## what; the tips section covers radar, battery and robots.

const GOAL_TEXT := "در ایستگاه K-17 برق قطع شده است. اول هر 3 پازل را حل کن تا برق وصل شود، بعد هر 3 دکل مخابراتی را روشن کن و در آخر با فرستنده‌ی اضطراری سیگنال را بفرست."
const CONTROLS_TEXT := "حرکت: WASD یا کلیدهای جهت‌دار\nتعامل: E\nپالس رادار: Q\nنقشه: M\nمکث: Esc"
const TIPS_TEXT := "با Q پالس رادار بزن تا اشیای مخفی و دشمن‌های نزدیک را ببینی.\nرادار باتری مصرف می‌کند؛ سلول انرژی و باتری جمع کن.\nربات‌ها اگر تو را ببینند تعقیبت می‌کنند؛ از دیدشان دور بمان. اگر گرفتار شدی، به ورودی برمی‌گردی.\nهر منطقه یک ربات دارد."

@onready var goal_label: Label = $Panel/Scroll/Content/GoalLabel
@onready var controls_label: Label = $Panel/Scroll/Content/ControlsLabel
@onready var tips_label: Label = $Panel/Scroll/Content/TipsLabel
@onready var back_button: Button = $Panel/Scroll/Content/BackButton


func _ready() -> void:
	goal_label.text = GOAL_TEXT
	controls_label.text = CONTROLS_TEXT
	tips_label.text = TIPS_TEXT
	back_button.pressed.connect(hide_help)


func show_help() -> void:
	visible = true
	back_button.grab_focus()


func hide_help() -> void:
	visible = false


func is_help_visible() -> bool:
	return visible
