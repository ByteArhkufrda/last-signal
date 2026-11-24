shader_type canvas_item;
// Last Signal — Medical Wing darkness (P2, 2026-11-24; port of step 4).
//
// Drawn on a ColorRect that covers exactly the medical room's rect, so
// UV * rect_size is the pixel offset inside that room, in the node's
// own (local) pixels — the same space light_center is given in. The
// rect is black everywhere except a soft circular hole (the flashlight)
// around light_center; darkness (0..1, already multiplied by the
// maximum opacity by the script) fades the whole effect in and out.
// Only UV and uniforms are used: it works in the GL Compatibility
// renderer.

// Size of the covered rect in px (set by the script).
uniform vec2 rect_size = vec2(640.0, 368.0);
// Flashlight centre, in px from the rect's top-left corner.
uniform vec2 light_center = vec2(0.0, 0.0);
// Px radius at which the light has fully faded to darkness.
uniform float light_radius = 35.0;
// Current opacity of the darkness: 0 = no effect, 0.95 = full darkness.
uniform float darkness : hint_range(0.0, 1.0) = 0.0;

// Fraction of the radius that is fully lit; the soft edge is the rest.
const float CLEAR_FRACTION = 0.45;

void fragment() {
	float dist = length(UV * rect_size - light_center);
	float shade = smoothstep(light_radius * CLEAR_FRACTION, light_radius, dist);
	COLOR = vec4(0.0, 0.0, 0.0, darkness * shade);
}
