shader_type canvas_item;
uniform float angle = 0.0;
void fragment() {
	vec2 p=(UV-vec2(.5))*2.0;
	float c=cos(angle),s=sin(angle);
	vec2 source=vec2(c*p.x+s*p.y,-s*p.x+c*p.y);
	vec2 pixel=vec2(835.0,500.0)+source*vec2(326.0,304.0);
	vec4 ink=texture(TEXTURE,pixel/vec2(1672.0,941.0));
	ink.a*=1.0-smoothstep(.995,1.0,length(p));
	COLOR=ink;
}
