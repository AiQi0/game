shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float reflection_height_pixels = 580.0;
uniform float ripple_amplitude_pixels = 8.0;
uniform float ripple_frequency = 18.0;
uniform float ripple_speed = 0.65;
uniform float shimmer_strength = 0.08;
uniform float top_blur_fraction = 0.25;
uniform float top_blur_radius_pixels = 6.0;

void fragment() {
	float reflection_offset_uv = UV.y * reflection_height_pixels * SCREEN_PIXEL_SIZE.y;
	float animated_phase = TIME * ripple_speed;
	float ripple = sin(UV.y * ripple_frequency + animated_phase) * 0.65;
	ripple += sin(UV.x * ripple_frequency * 0.35 - animated_phase * 1.4) * 0.35;
	float horizontal_offset_uv = ripple * ripple_amplitude_pixels * SCREEN_PIXEL_SIZE.x;
	vec2 sample_uv = vec2(SCREEN_UV.x + horizontal_offset_uv, SCREEN_UV.y - reflection_offset_uv * 2.0);
	vec4 reflected = texture(screen_texture, clamp(sample_uv, vec2(0.0), vec2(1.0)));
	float top_blur_mask = smoothstep(top_blur_fraction, 0.0, UV.y);
	vec2 blur_step = top_blur_radius_pixels * SCREEN_PIXEL_SIZE;
	vec4 blurred = reflected * 0.36;
	blurred += texture(screen_texture, clamp(sample_uv + vec2(blur_step.x, 0.0), vec2(0.0), vec2(1.0))) * 0.16;
	blurred += texture(screen_texture, clamp(sample_uv - vec2(blur_step.x, 0.0), vec2(0.0), vec2(1.0))) * 0.16;
	blurred += texture(screen_texture, clamp(sample_uv + vec2(0.0, blur_step.y), vec2(0.0), vec2(1.0))) * 0.16;
	blurred += texture(screen_texture, clamp(sample_uv - vec2(0.0, blur_step.y), vec2(0.0), vec2(1.0))) * 0.16;
	vec4 softened = mix(reflected, blurred, top_blur_mask);
	float shimmer = 1.0 + sin(UV.y * ripple_frequency * 0.7 - TIME * ripple_speed * 1.2) * shimmer_strength;
	COLOR = vec4(softened.rgb * shimmer, softened.a);
}
