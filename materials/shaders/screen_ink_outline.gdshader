// Full-screen ink lines from depth and normal edges. Draw on a 2x2 flipped QuadMesh in front of the camera.
shader_type spatial;
render_mode unshaded, fog_disabled, depth_test_disabled, depth_draw_never, cull_disabled, shadows_disabled;

#include "res://materials/shaders/toon_common.gdshaderinc"

global uniform vec4 toon_outline_color;
global uniform float toon_ink_width;
global uniform float toon_ink_depth_threshold;
global uniform float toon_ink_normal_threshold;
global uniform float toon_ink_color_tint;
global uniform float toon_ink_darken;
global uniform float toon_ink_max_distance;

uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;
uniform sampler2D normal_roughness_texture : hint_normal_roughness_texture, repeat_disable, filter_nearest;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

// Reversed Z: the far plane (sky) has depth 0.
const float SKY_DEPTH = 0.0;
// Lines start fading at this fraction of toon_ink_max_distance.
const float FADE_START_FRACTION = 0.5;
// Below one pixel the nearest-filtered samples would hit the centre pixel and miss edges.
const float MIN_INK_PIXELS = 1.0;

float linear_depth(vec2 uv, mat4 inv_projection) {
	float depth = texture(depth_texture, uv).r;
	vec4 view = inv_projection * vec4(uv * 2.0 - 1.0, depth, 1.0);
	return -view.z / view.w;
}

vec3 view_normal(vec2 uv) {
	return texture(normal_roughness_texture, uv).xyz * 2.0 - 1.0;
}

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	vec3 screen_color = texture(screen_texture, SCREEN_UV).rgb;
	ALBEDO = screen_color;

	if (texture(depth_texture, SCREEN_UV).r > SKY_DEPTH) {
		float center_depth = linear_depth(SCREEN_UV, INV_PROJECTION_MATRIX);
		vec3 center_normal = view_normal(SCREEN_UV);
		vec2 texel = max(toon_scaled_pixels(toon_ink_width, VIEWPORT_SIZE), MIN_INK_PIXELS) / VIEWPORT_SIZE;

		float edge = 0.0;
		for (int x = -1; x <= 1; x++) {
			for (int y = -1; y <= 1; y++) {
				vec2 uv = SCREEN_UV + vec2(float(x), float(y)) * texel;
				// One-sided: only the nearer surface draws the line, so it doesn't double up.
				float depth_diff = (linear_depth(uv, INV_PROJECTION_MATRIX) - center_depth) / center_depth;
				float normal_diff = length(view_normal(uv) - center_normal);
				if (depth_diff > toon_ink_depth_threshold || normal_diff > toon_ink_normal_threshold) {
					edge = 1.0;
				}
			}
		}

		edge *= 1.0 - smoothstep(toon_ink_max_distance * FADE_START_FRACTION, toon_ink_max_distance, center_depth);
		vec3 ink = mix(toon_outline_color.rgb, screen_color * (1.0 - toon_ink_darken), toon_ink_color_tint);
		ALBEDO = mix(screen_color, ink, edge);
	}
}
