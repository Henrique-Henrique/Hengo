shader_type canvas_item;

uniform vec2 screen_size = vec2(128., 128.);
uniform vec2 offset = vec2(0., 0.);
uniform float zoom_factor = 1.;
uniform float alpha = .2;
uniform sampler2D text: repeat_enable;
uniform float text_size = 128.;

void fragment() {
	vec2 myUV = UV;

	myUV *= screen_size / text_size;
	myUV += -(offset / text_size); // size of texture
	myUV /= zoom_factor;

	vec4 t = mix(texture(TEXTURE, myUV), texture(text, myUV), 1. - (zoom_factor - floor(zoom_factor)));
	COLOR = mix(t, vec4(.14, .14, .14, zoom_factor / 10.), .5);
	//if (zoom_factor <= .6) {
		//COLOR = texture(text, myUV);
	//}
}