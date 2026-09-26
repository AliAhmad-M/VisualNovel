shader_type canvas_item;

// Day to night slider
uniform float night_amount : hint_range(0.0, 1.0) = 0.0;

// Minimum brigthness
uniform float min_brightness : hint_range(0.0, 1.0) = 0.35;

// Night tint effect
uniform vec3 night_tint : source_color = vec3(0.15, 0.2, 0.45);

// How strongly the tint blends in
uniform float tint_strength : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);

	// Darken
	float brightness = mix(1.0, min_brightness, night_amount);
	vec3 darkened = tex_color.rgb * brightness;

	// Tint toward night_tint
	vec3 tinted = mix(darkened, darkened * night_tint * 2.0, tint_strength * night_amount);

	COLOR = vec4(tinted, tex_color.a);
}