shader_type canvas_item;
render_mode blend_add;

uniform float amp : hint_range(0.0, 1.5) = 0.5;
uniform float hue : hint_range(0.0, 1.0) = 0.0;
uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform float x_tint : hint_range(0.0, 1.0) = 0.0;
uniform bool neon_palette = false;

const float LED_ROWS = 22.0;
const float LED_COLS = 2.5;

vec3 hsv2rgb(vec3 c) {
	vec4 k = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + k.xyz) * 6.0 - k.www);
	return c.z * mix(k.xxx, clamp(p - k.xxx, 0.0, 1.0), c.y);
}

float led_mask(vec2 uv_led) {
	float my = smoothstep(0.12, 0.22, uv_led.y) * (1.0 - smoothstep(0.78, 0.88, uv_led.y));
	float mx = smoothstep(0.1, 0.2, uv_led.x) * (1.0 - smoothstep(0.8, 0.9, uv_led.x));
	return my * mx;
}

float vertical_spectrum_hue(float d) {
	float h;
	if (d < 0.1) {
		h = mix(0.52, 0.46, d / 0.1);
	} else if (d < 0.22) {
		h = mix(0.46, 0.32, (d - 0.1) / 0.12);
	} else if (d < 0.36) {
		h = mix(0.32, 0.16, (d - 0.22) / 0.14);
	} else if (d < 0.5) {
		h = mix(0.16, 0.07, (d - 0.36) / 0.14);
	} else if (d < 0.66) {
		h = mix(0.07, 0.0, (d - 0.5) / 0.16);
	} else if (d < 0.82) {
		h = mix(0.0, 0.92, (d - 0.66) / 0.16);
	} else {
		h = mix(0.92, 0.78, (d - 0.82) / 0.18);
	}
	return fract(h + hue * 0.16 + x_tint * 0.24);
}

void fragment() {
	float v = UV.y;
	float d = abs(v - 0.5) * 2.0;
	float edge = smoothstep(0.0, 0.08, v) * smoothstep(1.0, 0.92, v);
	float edge_fade = smoothstep(1.0, 0.62, d);

	vec2 led_uv = vec2(fract(UV.x * LED_COLS), fract(d * LED_ROWS));
	float block = led_mask(led_uv);
	block = max(block, 0.34);

	float center_line = 1.0 - smoothstep(0.0, 0.045, d);

	float h = neon_palette ? fract(hue + x_tint * 0.72 + d * 0.2) : vertical_spectrum_hue(d);
	float sat = 0.94 + d * 0.05;
	float val = 0.52 + d * 0.46 + amp * 0.22 + flash * 0.38;
	vec3 rgb = hsv2rgb(vec3(h, sat, val));

	vec3 cyan = mix(vec3(0.15, 0.88, 1.0), vec3(1.0, 1.0, 1.0), center_line);
	rgb = mix(rgb, cyan, center_line * 0.42);

	float tip_boost = smoothstep(0.72, 1.0, d);
	rgb += hsv2rgb(vec3(fract(h + 0.04), 0.85, tip_boost * (0.35 + amp * 0.4)));

	float a = edge * edge_fade * block * (0.28 + amp * 0.82);
	a += center_line * 0.18 * amp;
	if (neon_palette) { a *= 0.85; }
	COLOR = vec4(rgb * (1.0 + amp * 0.65 + flash * 0.28), a);
}
