shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest_mipmap;
uniform float lod: hint_range(0.0, 5) = 0.0;
uniform vec4 color: source_color;
uniform float transparency: hint_range(0.0, 1.0) = .4;

void fragment(){
    COLOR = mix(
		textureLod(screen_texture, SCREEN_UV, lod),
		color,
		transparency
	);
}