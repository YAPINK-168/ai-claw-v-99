shader_type canvas_item;
render_mode unshaded;
// These poses contain only exposed rope beyond this column. Fade that painted
// extension into the live rope behind it; preserve the face, hands and rope tail.
uniform float rope_edge_px = 740.0;
uniform float canvas_width_px = 768.0;
void fragment() {
	float fade = 1.0-smoothstep(rope_edge_px-6.0,rope_edge_px+8.0,UV.x*canvas_width_px);
	COLOR.a *= fade;
}
