// Inverted-hull outline with a constant screen-space width. Use as next_pass of a toon material.
shader_type spatial;
render_mode unshaded, cull_front;

#include "res://materials/shaders/toon_common.gdshaderinc"

global uniform vec4 toon_outline_color;
global uniform float toon_outline_width;

// Avoids normalizing a zero vector when the normal points straight at the camera.
const float MIN_DIRECTION_LENGTH = 0.0001;
// Clip-space point outside the frustum; collapsing every vertex there removes the hull.
const vec4 CULLED_POSITION = vec4(2.0, 2.0, 2.0, 1.0);

void vertex() {
	// Skipped in the shadow pass so the hull doesn't enlarge shadows.
	if (toon_outline_width <= 0.0 || IN_SHADOW_PASS) {
		POSITION = CULLED_POSITION;
	} else {
		vec4 clip = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
		vec3 view_normal = MODELVIEW_NORMAL_MATRIX * NORMAL;
		vec2 clip_normal = (PROJECTION_MATRIX * vec4(view_normal, 0.0)).xy;
		// Work in pixel space so the width is the same horizontally and vertically.
		vec2 pixel_dir = clip_normal * VIEWPORT_SIZE;
		pixel_dir /= max(length(pixel_dir), MIN_DIRECTION_LENGTH);
		float width_px = toon_scaled_pixels(toon_outline_width, VIEWPORT_SIZE);
		// One pixel is 2 / VIEWPORT_SIZE in NDC; multiply by w to stay in clip space.
		clip.xy += pixel_dir * width_px * 2.0 / VIEWPORT_SIZE * clip.w;
		POSITION = clip;
	}
}

void fragment() {
	ALBEDO = toon_outline_color.rgb;
}
