shader_type spatial;
render_mode blend_mix, unshaded, cull_disabled, depth_prepass_alpha;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap;
/// 整体 RGB 倍率（仅背景贴图；<1 压暗，避免用 alpha 压高光）
uniform float brightness : hint_range(0.5, 1.5, 0.01) = 1.0;
/// 饱和度：略提可恢复蓝天，高光区由 rolloff 保护
uniform float saturation : hint_range(0.5, 1.5, 0.01) = 1.0;
/// 以 0.5 为中心的对比度，>1 恢复层次
uniform float contrast : hint_range(0.85, 1.25, 0.01) = 1.0;
/// 高于 threshold 的亮度按此强度压缩（越大压高光越多）
uniform float highlight_rolloff : hint_range(0.0, 3.0, 0.01) = 0.0;
/// 从此亮度以上开始压高光（线性空间近似）
uniform float highlight_threshold : hint_range(0.45, 0.95, 0.01) = 0.72;
uniform float alpha_scissor : hint_range(0.0, 1.0, 0.01) = 0.0;

vec3 compress_highlights(vec3 col, float threshold, float rolloff) {
	if (rolloff <= 0.0001) {
		return col;
	}
	float peak = max(max(col.r, col.g), col.b);
	if (peak <= threshold) {
		return col;
	}
	float excess = peak - threshold;
	float denom = 1.0 + rolloff * excess;
	float new_peak = threshold + excess / denom;
	return col * (new_peak / max(peak, 1e-5));
}

void fragment() {
	vec4 tex = texture(albedo_tex, UV);
	if (alpha_scissor > 0.0 && tex.a < alpha_scissor) {
		discard;
	}
	vec3 col = tex.rgb;
	float luma = dot(col, vec3(0.2126, 0.7152, 0.0722));
	col = mix(vec3(luma), col, saturation);
	col = (col - 0.5) * contrast + 0.5;
	col = compress_highlights(col, highlight_threshold, highlight_rolloff);
	col *= brightness;
	col = clamp(col, vec3(0.0), vec3(1.0));
	ALBEDO = col;
	ALPHA = tex.a;
}
