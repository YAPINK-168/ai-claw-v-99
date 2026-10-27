shader_type canvas_item;
render_mode blend_mix;
uniform bool shootable = false;
varying vec4 instance_tint;
void vertex() { instance_tint = COLOR; }
void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec4 tint = instance_tint;
	float value = max(tex.r, max(tex.g, tex.b));
	float core = smoothstep(0.82, 1.0, min(tex.r, min(tex.g, tex.b)));
	vec3 neon = mix(tint.rgb * value, vec3(1.15), core * 0.18);
	// Gold missile casing remains identifiable throughout the color cycle.
	bool gold = tex.r > tex.b * 1.4 && tex.g > tex.b * 1.1;
	if (shootable && gold) { neon = tex.rgb * 1.12; }
	COLOR = vec4(neon, tex.a * tint.a);
}
