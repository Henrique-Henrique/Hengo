shader_type canvas_item;

uniform float dash_amount: hint_range(0.0, 1.0) = 0.0;
uniform float scroll_speed = 2.0;

varying vec4 v_color;

void vertex() {
	v_color = COLOR;
}

// blends between a solid line and a scrolling dashed line
void fragment() {
	float dash = texture(TEXTURE, vec2(UV.x - TIME * scroll_speed, UV.y)).a;
	COLOR = vec4(v_color.rgb, v_color.a * mix(1.0, dash, dash_amount));
}
