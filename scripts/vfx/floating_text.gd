class_name FloatingText
extends Label3D
## A short popup over a unit ("-12", "Miss", "DEF ↑"): waits, appears, rises and fades,
## then frees itself. Billboard / depth settings live in the scene; text, colour and
## timing come from FloatingTextSpawner.

## Share of the duration after which the fade-out starts.
const FADE_START: float = 0.5


## Shows text in color, scaled by size_scale, after delay; rises by rise over duration.
func play(popup_text: String, color: Color, size_scale: float, rise: float, duration: float, delay: float) -> void:
	text = popup_text
	modulate = color
	scale *= size_scale
	hide()
	var tween: Tween = create_tween()
	tween.tween_interval(delay)
	tween.tween_callback(show)
	tween.tween_property(self, "position:y", position.y + rise, duration) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(self, "modulate:a", 0.0, duration * (1.0 - FADE_START)) \
			.set_delay(duration * FADE_START)
	tween.tween_callback(queue_free)
