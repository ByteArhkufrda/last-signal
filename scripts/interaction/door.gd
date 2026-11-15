extends StaticBody2D
## Last Signal — Door interactable (Phase 3).
##
## Same interactable interface as console.gd (group "interactable" +
## interact_label / interact() / set_highlighted()). Toggling open disables
## the collision shape (deferred, so it applies safely mid-physics) and
## slides the two leaves apart. The door's visual is code-drawn placeholder
## metal: the atlas has no sci-fi door (its doors are wooden/fantasy).
## See docs/KNOWN_ISSUES.md.

signal interacted(door: StaticBody2D)

var interact_label: String = "باز کردن در"
var message: String = "Door closed."

var is_open: bool = false

@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var leaf_left: Polygon2D = $LeafLeft
@onready var leaf_right: Polygon2D = $LeafRight

var _leaf_left_base_x: float = 0.0
var _leaf_right_base_x: float = 0.0


func _ready() -> void:
	_leaf_left_base_x = leaf_left.position.x
	_leaf_right_base_x = leaf_right.position.x


func interact() -> void:
	is_open = not is_open
	interact_label = "بستن در" if is_open else "باز کردن در"
	message = "در باز شد." if is_open else "در بسته شد."
	collision.set_deferred("disabled", is_open)
	leaf_left.position.x = _leaf_left_base_x - 10.0 if is_open else _leaf_left_base_x
	leaf_right.position.x = _leaf_right_base_x + 10.0 if is_open else _leaf_right_base_x
	leaf_left.modulate = Color(0.55, 0.55, 0.6) if is_open else Color.WHITE
	leaf_right.modulate = Color(0.55, 0.55, 0.6) if is_open else Color.WHITE
	interacted.emit(self)


func set_highlighted(highlighted: bool) -> void:
	modulate = Color(1.4, 1.3, 0.7) if highlighted else Color.WHITE
