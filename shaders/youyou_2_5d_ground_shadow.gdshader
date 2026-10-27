shader_type spatial;
render_mode blend_mix, cull_disabled, unshaded;

uniform float strength = 0.30;
uniform vec3 shadow_color : source_color = vec3(0.22, 0.08, 0.28);
uniform vec2 ellipse_scale = vec2(0.28, 0.11);

void fragment() {
	vec2 p = UV - vec2(0.5);
	float d = length(p / max(ellipse_scale, vec2(0.001)));
	float alpha = smoothstep(1.0, 0.15, d) * strength;
	ALBEDO = shadow_color;
	ALPHA = alpha;
}
