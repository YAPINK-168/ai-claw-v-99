shader_type canvas_item;
render_mode unshaded;

uniform sampler2D sky_tex : filter_linear;
uniform float scroll_px;
uniform float tile_h_px;
uniform float view_h_px;
uniform float one_shot; // 1=长图单向滚到底，0=短图循环
uniform bool neon_backdrop = false;

void fragment() {
	float th = max(tile_h_px, 1.0);
	float vh = max(view_h_px, 1.0);
	float ypix = UV.y * vh;
	vec4 col;
	if (neon_backdrop) {
		vec2 uv = vec2(UV.x * 0.96 + 0.02, UV.y * 0.94 + 0.03 + sin(scroll_px * 0.0008) * 0.02);
		col = texture(sky_tex, uv);
	} else if (one_shot > 0.5) {
		// 从长图底部开局，沿图片向上滚到顶部后停住
		float max_off = max(th - vh, 0.0);
		float traveled = clamp(-scroll_px, 0.0, max_off);
		float off = max_off - traveled;
		float v = clamp((off + ypix) / th, 0.0, 1.0);
		col = texture(sky_tex, vec2(UV.x, v));
	} else {
		float v = fract((scroll_px + ypix) / th);
		float v_in = clamp(v, 0.002, 0.998);
		col = texture(sky_tex, vec2(UV.x, v_in));
		float seam = 0.022;
		if (v > 1.0 - seam) {
			float k = smoothstep(1.0 - seam, 1.0, v);
			float v_top = mix(0.004, 0.035, (v - (1.0 - seam)) / seam);
			vec4 head = texture(sky_tex, vec2(UV.x, v_top));
			col = mix(col, head, k * 0.55);
		}
	}
	COLOR = col * COLOR;
}
