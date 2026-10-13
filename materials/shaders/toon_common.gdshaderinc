// Shared helpers for the Evermore toon shaders.

// Pixel widths in the toon globals are authored for a 1080p viewport.
const float TOON_REFERENCE_HEIGHT = 1080.0;

// Converts a width authored at 1080p into pixels for the current viewport.
float toon_scaled_pixels(float width_at_1080p, vec2 viewport_size) {
	return width_at_1080p * (viewport_size.y / TOON_REFERENCE_HEIGHT);
}
