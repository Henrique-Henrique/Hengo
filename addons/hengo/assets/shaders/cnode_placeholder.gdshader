shader_type canvas_item;

// dashed-border placeholder for queued/virtual cnodes.
// static (no TIME) — same output every frame, slightly cheaper per-fragment.
// shared by the whole pool — uv-space so any size works with a single material.

uniform vec4 border_color : source_color = vec4(0.78, 0.82, 0.95, 0.85);
uniform float border_thickness : hint_range(0.0005, 0.02) = 0.008;
uniform float corner_radius : hint_range(0.0, 0.5) = 0.08;
uniform float dash_count : hint_range(4.0, 80.0) = 24.0;
uniform float dash_ratio : hint_range(0.05, 0.95) = 0.55;
uniform vec4 fill_color : source_color = vec4(0.6, 0.7, 1.0, 0.0);


float rounded_rect_sdf(vec2 p, vec2 half_size, float r) {
	vec2 d = abs(p) - half_size + vec2(r);
	return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - r;
}

void fragment() {
	vec2 p = UV - 0.5;
	vec2 half_size = vec2(0.5);

	float d = rounded_rect_sdf(p, half_size, corner_radius);
	float aa = fwidth(d);

	// border ring mask
	float on_border = smoothstep(border_thickness + aa, border_thickness - aa, abs(d));

	// static dashes via angular parameterization around the center.
	// for non-square nodes dashes pack slightly tighter at the short edges.
	float ang = atan(p.y, p.x);
	float t = ang / 6.2831853 + 0.5;

	float dash_phase = fract(t * dash_count);
	float dash_aa = 1.5 / dash_count;
	float dash = smoothstep(dash_ratio + dash_aa, dash_ratio - dash_aa, dash_phase);

	// optional very-faint fill inside the rounded shape
	float inside = smoothstep(aa, -aa, d);
	vec4 fill = vec4(fill_color.rgb, fill_color.a * inside);

	float border_alpha = on_border * dash * border_color.a;
	vec3 rgb = mix(fill.rgb, border_color.rgb, border_alpha);
	float alpha = max(fill.a, border_alpha);

	COLOR = vec4(rgb, alpha);
}
