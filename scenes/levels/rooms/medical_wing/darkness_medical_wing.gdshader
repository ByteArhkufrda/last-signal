shader_type canvas_item;
// Last Signal — Medical Wing darkness (P2, 2026-11-24; reworked in P5,
// 2026-11-26).
//
// Drawn on a ColorRect that covers exactly the medical room's rect, so
// UV * rect_size is the pixel offset inside that room, in the node's
// own (local) pixels — the same space light_center and zone_rect are
// given in. Two kinds of darkness share the overlay:
//   * room_darkness: the whole room (a flicker pulse of the emergency
//     lights);
//   * zone_darkness: only inside zone_rect, the room's one permanently
//     dark spot, with a soft edge.
// Both are opacities (0..1, already multiplied by the maximum opacity by
// the script). The darker of the two wins at every pixel. A soft circular
// hole (the flashlight, or the tiny circle without it) is cut around
// light_center out of both. Only UV and uniforms are used: it works in
// the GL Compatibility renderer.

// Size of the covered rect in px (set by the script).
uniform vec2 rect_size = vec2(640.0, 368.0);
// Light centre, in px from the rect's top-left corner.
uniform vec2 light_center = vec2(0.0, 0.0);
// Px radius at which the light has fully faded to darkness (0 = no light).
uniform float light_radius = 35.0;
// Current opacity of the whole-room darkness (a flicker pulse).
uniform float room_darkness : hint_range(0.0, 1.0) = 0.0;
// Current opacity of the dark zone's darkness.
uniform float zone_darkness : hint_range(0.0, 1.0) = 0.0;
// The dark zone: x, y, width, height in px from the rect's top-left corner.
uniform vec4 zone_rect = vec4(0.0, 0.0, 0.0, 0.0);

// Fraction of the radius that is fully lit; the soft edge is the rest.
const float CLEAR_FRACTION = 0.45;
// Width in px of the dark zone's soft edge (half inside, half outside).
const float ZONE_FEATHER = 8.0;

void fragment() {
	vec2 px = UV * rect_size;
	// A radius of 0 means "no light": keep smoothstep's edges apart.
	float radius = max(light_radius, 0.001);
	float shade = smoothstep(radius * CLEAR_FRACTION, radius, length(px - light_center));
	// Distance in px to the zone's nearest edge: > 0 inside, < 0 outside.
	vec2 edge = min(px - zone_rect.xy, zone_rect.xy + zone_rect.zw - px);
	float in_zone = smoothstep(-0.5 * ZONE_FEATHER, 0.5 * ZONE_FEATHER, min(edge.x, edge.y));
	float dark = max(room_darkness, zone_darkness * in_zone);
	COLOR = vec4(0.0, 0.0, 0.0, dark * shade);
}
