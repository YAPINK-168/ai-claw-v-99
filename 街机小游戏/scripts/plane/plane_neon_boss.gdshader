shader_type canvas_item;
render_mode blend_mix, unshaded;
uniform float damage_stage = 0.0;
uniform bool flagship = false;
uniform bool use_regions = false;
uniform vec4 cut_0 = vec4(0.0);
uniform vec4 cut_1 = vec4(0.0);
uniform vec4 cut_2 = vec4(0.0);
varying vec4 sprite_tint;

bool in_cut(vec2 uv, vec4 bounds) {
	return uv.x >= bounds.x && uv.y >= bounds.y && uv.x < bounds.z && uv.y < bounds.w;
}

void vertex() {
	sprite_tint = COLOR;
}

void fragment() {
	vec4 c = texture(TEXTURE, UV) * sprite_tint;
	if (use_regions) {
		if (damage_stage >= 1.0 && in_cut(UV,cut_0)) { c.a = 0.0; }
		if (damage_stage >= 2.0 && in_cut(UV,cut_1)) { c.a = 0.0; }
		if (damage_stage >= 3.0 && in_cut(UV,cut_2)) { c.a = 0.0; }
		COLOR = c;
	} else if (flagship) {
		if (damage_stage >= 1.0 && UV.x > 0.43359375 && UV.x < 0.56640625 && UV.y < 0.34375) { c.a = 0.0; }
		if (damage_stage >= 2.0 && UV.x < 0.33984375 && UV.y >= 0.25) { c.a = 0.0; }
		if (damage_stage >= 3.0 && UV.x >= 0.66015625 && UV.y >= 0.25) { c.a = 0.0; }
		COLOR = c;
	} else {
	// Detach the selected boss's actual outer crystal nodes, never old metal parts.
	bool side_band = UV.y > 0.34 && UV.y < 0.72;
	if (damage_stage >= 1.0 && UV.x > 0.39 && UV.x < 0.61 && UV.y < 0.24) { c.a = 0.0; }
	if (damage_stage >= 2.0 && UV.x < 0.25 && side_band) { c.a = 0.0; }
	if (damage_stage >= 3.0 && UV.x > 0.75 && side_band) { c.a = 0.0; }
	COLOR = c;
	}
}
