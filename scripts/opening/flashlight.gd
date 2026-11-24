class_name Flashlight
extends PointLight2D
## Last Signal — opening sequence: directional flashlight.
##
## A PointLight2D whose texture is a soft cone generated in code: about
## a 50-degree opening angle, warm-white, with a smooth angular falloff
## and a radial falloff so the visibility boundary feels natural instead
## of a hard geometric cone. The light is steady (the emergency lights
## flicker instead). `set_facing()` rotates the cone to the character's
## facing direction. Works with the room's CanvasModulate: the room is
## dim, the cone brightens what it covers, and the rest stays readable.

const CONE_HALF_ANGLE := deg_to_rad(25.0)
const CONE_EDGE_FADE := deg_to_rad(7.0)
const TEXTURE_SIZE := 256
## World-space reach of the cone (texture radius 128 * scale).
const RANGE_PX := 180.0


func _ready() -> void:
	texture = _make_cone_texture()
	texture_scale = RANGE_PX / (TEXTURE_SIZE * 0.5)
	color = Color(1.0, 0.95, 0.82)
	energy = 1.1
	position = Vector2(8, -12)


func set_facing(direction: int) -> void:
	rotation = 0.0 if direction >= 0 else PI


func _make_cone_texture() -> ImageTexture:
	var image := Image.create(TEXTURE_SIZE, TEXTURE_SIZE, false, Image.FORMAT_RGBA8)
	var center := Vector2(TEXTURE_SIZE * 0.5, TEXTURE_SIZE * 0.5)
	var radius := TEXTURE_SIZE * 0.5
	for y in TEXTURE_SIZE:
		for x in TEXTURE_SIZE:
			var offset := Vector2(x, y) - center
			var dist := offset.length()
			if dist > radius:
				continue
			# Angle from the +X axis; the cone opens to the right.
			var angle := absf(offset.angle())
			var angular := 1.0 - clampf(
				(angle - CONE_HALF_ANGLE) / CONE_EDGE_FADE, 0.0, 1.0)
			# Radial falloff: full near the source, fading to zero at
			# the edge (smoothstep keeps the boundary soft).
			var t := clampf(dist / radius, 0.0, 1.0)
			var radial := 1.0 - t * t * (3.0 - 2.0 * t)
			var alpha := angular * radial
			if alpha > 0.003:
				image.set_pixel(x, y, Color(1, 1, 1, alpha))
	return ImageTexture.create_from_image(image)
