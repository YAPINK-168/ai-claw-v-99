shader_type canvas_item;
render_mode blend_add;

uniform float beat = 0.0;
uniform float climax = 0.0;
uniform float trail_strength = 0.0;
uniform float accent = 0.0;
varying vec4 instance_tint;
void vertex() { instance_tint = COLOR; }

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float cfx = clamp(climax, 0.0, 3.0);
	float pulse = 1.0 + clamp(beat, 0.0, 1.75) * 0.38 + clamp(accent, 0.0, 1.0) * 0.30 + cfx * 0.06;
	// 针弹亮点在 UV 顶部；只加强弹体尾部，不能抹掉弹头
	float head = 1.0 - smoothstep(0.0, 0.38, UV.y);
	float streak = smoothstep(0.16, 1.0, UV.y);
	float tail_mul = clamp(max(head, streak * (0.5 + beat * 0.55)), 0.35, 1.0);
	float a = c.a * instance_tint.a;
	a *= mix(1.0, tail_mul, clamp(trail_strength, 0.0, 1.0));
	float value = max(c.r, max(c.g, c.b));
	float core = smoothstep(0.88, 1.0, min(c.r, min(c.g, c.b)));
	vec3 neon = mix(instance_tint.rgb * value, vec3(1.15), core * 0.12);
	COLOR = vec4(neon * pulse, a);
}
