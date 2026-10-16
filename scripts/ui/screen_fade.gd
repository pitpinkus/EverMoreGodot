class_name ScreenFade
extends CanvasLayer
## Full-screen fade to and from black (%Overlay), e.g. around scene changes.
## The scene root uses process_mode ALWAYS so fades also run while paused.

@onready var _overlay: CanvasItem = %Overlay


func _ready() -> void:
	_overlay.modulate.a = 0.0
	_overlay.hide()


## Fades to fully covered over duration seconds. Await it.
func fade_out(duration: float) -> void:
	_overlay.show()
	await _fade_to(1.0, duration)


## Fades back to fully visible over duration seconds. Await it.
func fade_in(duration: float) -> void:
	await _fade_to(0.0, duration)
	_overlay.hide()


func _fade_to(alpha: float, duration: float) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(_overlay, "modulate:a", alpha, duration)
	await tween.finished
