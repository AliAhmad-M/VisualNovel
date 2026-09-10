shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float curvature : hint_range(1.0, 50.0) = 16.0;
uniform float strength : hint_range(0.0, 1.0) = 0.5;

void fragment() {
    vec2 original_uv = SCREEN_UV;
    vec2 centered_uv = original_uv * 2.0 - 1.0;
    
    // Distortion
    vec2 uv_offset = centered_uv.yx / curvature;
    vec2 warped_uv = centered_uv + centered_uv * (uv_offset * uv_offset);
    vec2 distorted_uv = (warped_uv + 1.0) / 2.0;
    
    // Interpolate between flat and distorted UVs
    vec2 final_uv = mix(original_uv, distorted_uv, strength);
    
    // Cutoff mask
    float cutoff = step(0.0, final_uv.x) * step(final_uv.x, 1.0) *
                   step(0.0, final_uv.y) * step(final_uv.y, 1.0);
    
    // Fetch textures
    vec3 base_color = texture(screen_texture, original_uv).rgb;
    
    vec3 scanlines = vec3(sin(warped_uv.y * 360.0) * (0.2 * strength) + 1.0);
    vec3 vignette = vec3(length(pow(abs(centered_uv), vec2(4.0 / 3.0))));
    
    vec3 crt_color = textureLod(screen_texture, final_uv, 0.2 * strength).rgb * scanlines * cutoff;
    crt_color -= (vignette * 0.1 * strength) * cutoff;
    
    // Blend final output
    COLOR = vec4(mix(base_color, crt_color, strength), 1.0);
}