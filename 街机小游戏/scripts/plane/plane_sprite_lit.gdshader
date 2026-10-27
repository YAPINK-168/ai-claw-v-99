shader_type canvas_item;
render_mode blend_mix, unshaded;
varying vec4 sprite_tint;

void vertex() {
	sprite_tint = COLOR;
}

void fragment() {
	vec4 c = texture(TEXTURE, UV) * sprite_tint;
	float hi = max(c.r, max(c.g, c.b));
	float lo = min(c.r, min(c.g, c.b));
	float live = step(0.04, c.a);
	vec3 spec = vec3(0.06, 0.11, 0.16) * pow(hi, 6.0);
	vec3 rim = c.rgb * (0.10 + 0.16 * (hi - lo));
	vec3 rgb = mix(c.rgb, clamp(c.rgb * 1.05 + spec + rim * 0.35, vec3(0.0), vec3(1.45)), live);
	COLOR = vec4(rgb, c.a);
}
