shader_type canvas_item;
render_mode unshaded;
void fragment() {
	// The original braid's transparent scalloped silhouette changes between rows.
	// Sample its opaque interior and keep a fixed, softly outlined rope silhouette.
	vec3 ink = texture(TEXTURE,vec2(mix(0.20,0.80,UV.x),UV.y)).rgb;
	float face = smoothstep(0.0,0.13,UV.x)*(1.0-smoothstep(0.87,1.0,UV.x));
	float alpha = smoothstep(0.0,0.075,UV.x)*(1.0-smoothstep(0.925,1.0,UV.x));
	COLOR = vec4(mix(vec3(0.48,0.25,0.08),ink,face),alpha);
}
