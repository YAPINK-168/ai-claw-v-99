shader_type canvas_item;
render_mode blend_add;

uniform float amp : hint_range(0.0, 1.5) = 0.5;
uniform float hue : hint_range(0.0, 1.0) = 0.0;
uniform float flash : hint_range(0.0, 1.0) = 0.0;

vec3 hsv2rgb(vec3 c) {
	vec4 k = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + k.xyz) * 6.0 - k.www);
	return c.z * mix(k.xxx, clamp(p - k.xxx, 0.0, 1.0), c.y);
}

void fragment() {
	float v = UV.y;
	float edge = smoothstep(0.0, 0.14, v) * smoothstep(1.0, 0.86, v);
	float mid_glow = 1.0 - smoothstep(0.0, 0.08, abs(v - 0.5) * 2.0);
	float bright = 0.28 + v * 0.82 + flash * 0.25 + amp * 0.12;
	vec3 rgb = hsv2rgb(vec3(hue, 0.88, bright));
	float a = edge * (0.18 + amp * 0.82) + mid_glow * 0.12 * amp;
	COLOR = vec4(rgb * (1.0 + amp * 0.55), a);
}
