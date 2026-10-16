// Cel-shaded surface: banded diffuse, tinted shadows, hard specular and rim light.
shader_type spatial;

global uniform float toon_band_count;
global uniform float toon_band_softness;
global uniform vec4 toon_shadow_tint;
global uniform float toon_specular_size;
global uniform float toon_specular_strength;
global uniform vec4 toon_rim_color;
global uniform float toon_rim_strength;
global uniform float toon_rim_width;

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D albedo_texture : source_color, hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float specular_amount : hint_range(0.0, 1.0) = 0.0;
// Off by default: on large flat surfaces the rim term draws an arc around the camera.
uniform float rim_amount : hint_range(0.0, 1.0) = 0.0;
// Recolours the texture before the albedo tint (a multiply tint can't turn red into
// orange). Hue rotation in turns and a brightness factor; the defaults change nothing.
uniform float hue_shift : hint_range(-0.5, 0.5) = 0.0;
uniform float value_scale : hint_range(0.0, 3.0) = 1.0;
// Optional glow; the default black texture emits nothing.
uniform sampler2D emission_texture : source_color, hint_default_black, filter_linear_mipmap, repeat_enable;
uniform float emission_strength : hint_range(0.0, 16.0) = 1.0;

// Keeps smoothstep edges valid when a softness global is set to 0.
const float MIN_SOFTNESS = 0.0001;

// Steps value (0..1) into toon_band_count levels; each step rises over toon_band_softness.
float toon_band(float value) {
	float count = max(toon_band_count, 1.0);
	float scaled = clamp(value, 0.0, 1.0) * count;
	float rise = max(toon_band_softness * count, MIN_SOFTNESS);
	return (floor(scaled) + smoothstep(0.0, rise, fract(scaled))) / count;
}

// HSV conversion (Sam Hocevar's branchless form) for hue_shift / value_scale.
vec3 rgb_to_hsv(vec3 c) {
	vec4 k = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, k.wz), vec4(c.gb, k.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv_to_rgb(vec3 c) {
	vec4 k = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + k.xyz) * 6.0 - k.www);
	return c.z * mix(k.xxx, clamp(p - k.xxx, 0.0, 1.0), c.y);
}

// Hard threshold at 1 - size, softened by toon_band_softness.
float toon_hard_edge(float value, float size) {
	float soft = max(toon_band_softness, MIN_SOFTNESS);
	float edge = 1.0 - size;
	return smoothstep(edge - soft, edge + soft, value);
}

void fragment() {
	vec3 hsv = rgb_to_hsv(texture(albedo_texture, UV).rgb);
	hsv.x = fract(hsv.x + hue_shift);
	hsv.z *= value_scale;
	ALBEDO = albedo.rgb * hsv_to_rgb(hsv);
	EMISSION = texture(emission_texture, UV).rgb * emission_strength;
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
	SPECULAR = 0.0;
}

void light() {
	vec3 light_color = LIGHT_COLOR / PI;
	float band = toon_band(min(dot(NORMAL, LIGHT), ATTENUATION));

	if (LIGHT_IS_DIRECTIONAL) {
		DIFFUSE_LIGHT += light_color * mix(toon_shadow_tint.rgb, vec3(1.0), band);
	} else {
		DIFFUSE_LIGHT += light_color * band;
	}

	float n_dot_h = clamp(dot(NORMAL, normalize(LIGHT + VIEW)), 0.0, 1.0);
	float specular = toon_hard_edge(n_dot_h, toon_specular_size) * toon_specular_strength * specular_amount;

	float rim_factor = 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	vec3 rim = toon_rim_color.rgb * toon_hard_edge(rim_factor, toon_rim_width) * toon_rim_strength * rim_amount;

	SPECULAR_LIGHT += light_color * (vec3(specular) + rim) * band;
}
