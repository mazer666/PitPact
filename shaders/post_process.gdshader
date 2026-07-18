// PitPact — M11 Bucket 3:
// Post-Processing Shader.
//
// The M11 closeout ships a
// canvas-item shader that
// applies Bloom (subtle glow
// on highlights), Vignette
// (darker corners), and
// Color-Grade (warm shadows,
// cool highlights, brightness)
// to the scene.
//
// The shader is driven by
// the `TimeOfDay` carrier
// (per ADR-0023). The
// parameters are passed via
// the shader's uniforms.
//
// Performance: the shader is
// 60 FPS capable on 4-year-old
// hardware (per ADR-0023
// performance budget).

shader_type canvas_item;
render_mode blend_mix;

// Bloom strength (0.0 = no bloom,
// 1.0 = strong bloom). The M11
// closeout's default is 0.4
// (subtle).
uniform float bloom_strength : hint_range(0.0, 1.0) = 0.4;

// Vignette strength (0.0 = no
// vignette, 1.0 = very dark
// corners).
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.6;

// Vignette radius (0.0 = vignette
// covers whole screen, 1.0 =
// vignette only at corners).
uniform float vignette_radius : hint_range(0.0, 1.0) = 0.7;

// Color-grade parameters (set
// by `TimeOfDay.color_grade()`).
uniform float warm_shift : hint_range(-1.0, 1.0) = 0.0;
uniform float cool_shift : hint_range(-1.0, 1.0) = 0.0;
uniform float brightness : hint_range(0.0, 2.0) = 1.0;


void fragment() {
	vec4 color = texture(TEXTURE, UV);
	vec3 rgb = color.rgb;

	// Bloom: brighten highlights
	// (pixels brighter than 0.5).
	float luminance = dot(rgb, vec3(0.299, 0.587, 0.114));
	vec3 bloom = rgb * smoothstep(0.5, 1.0, luminance) * bloom_strength;
	rgb += bloom;

	// Vignette: darken corners.
	vec2 vignette_uv = UV - 0.5;
	float vignette_distance = length(vignette_uv);
	float vignette = smoothstep(vignette_radius, vignette_radius * 0.5, vignette_distance);
	rgb *= mix(1.0 - vignette_strength, 1.0, vignette);

	// Color-grade: warm shift
	// (boost R, slight G).
	rgb.r += warm_shift * 0.1;
	rgb.g += warm_shift * 0.05;
	// Cool shift (boost B, slight G).
	rgb.b += cool_shift * 0.1;
	rgb.g += cool_shift * 0.05;
	// Brightness.
	rgb *= brightness;

	// Clamp to [0, 1].
	rgb = clamp(rgb, vec3(0.0), vec3(1.0));

	COLOR = vec4(rgb, color.a);
}
