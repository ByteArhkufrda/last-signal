shader_type canvas_item;
// Last Signal — Medical Wing pain vignette (P7, 2026-11-27).
//
// Drawn on a ColorRect in the WORLD canvas that covers the medical room
// plus a margin, so UV * rect_size is a pixel offset inside that rect, in
// the node's own (local) pixels. The vignette itself is a SCREEN effect:
// view_rect (set by the script every frame from the viewport's canvas
// transform) is the part of that rect the camera shows right now, so the
// shade is computed from where the pixel lies ON SCREEN, whatever the
// camera does. The HUD is a CanvasLayer and always draws above the world
// canvas, so it is never covered.
//
// The shade is 0 in the middle of the screen and reaches `strength` (the
// opacity, 0..1) at every screen edge: the "edge" measure is a rounded
// square (a 4-norm), 1.0 on the four edges and a little more in the
// corners. Only UV and uniforms are used: it works in the GL
// Compatibility renderer.

// Size of the covered rect in px (set by the script).
uniform vec2 rect_size = vec2(1320.0, 1048.0);
// The visible part of the rect: x, y, width, height in px from the rect's
// top-left corner (set by the script).
uniform vec4 view_rect = vec4(0.0, 0.0, 640.0, 360.0);
// Opacity at the screen edge (the script drives it: pulse x presence x relief).
uniform float strength : hint_range(0.0, 1.0) = 0.0;
// Colour of the vignette (a very dark red).
uniform vec4 vignette_color : source_color = vec4(0.1, 0.0, 0.02, 1.0);

// Fraction of the half-screen that stays completely clear in the middle.
const float CLEAR_FRACTION = 0.55;

void fragment() {
	vec2 px = UV * rect_size;
	// 0..1 across the visible screen area, (0.5, 0.5) in the middle.
	vec2 screen = (px - view_rect.xy) / max(view_rect.zw, vec2(0.001));
	// 0 in the middle, 1 on the edges, along each axis.
	vec2 d = abs(screen - vec2(0.5)) * 2.0;
	float edge = pow(pow(d.x, 4.0) + pow(d.y, 4.0), 0.25);
	float shade = smoothstep(CLEAR_FRACTION, 1.0, edge);
	COLOR = vec4(vignette_color.rgb, shade * strength);
}
