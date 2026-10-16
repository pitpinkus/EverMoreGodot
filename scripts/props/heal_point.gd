class_name HealPoint
extends Node3D
## Touching it fully heals the party and makes it the place the player returns to
## after losing a battle (%RespawnMarker: position and facing, -Z forward).
## Shows %FeedbackLabel briefly, once per entry into %Area.

signal party_healed

@export var player_group: StringName = &"player"
@export_multiline var feedback_text: String = "Your monsters are fully healed!"
@export_range(0.1, 10.0, 0.1, "suffix:s") var feedback_duration: float = 2.0

var _feedback_tween: Tween

@onready var _area: Area3D = %Area
@onready var _respawn_marker: Node3D = %RespawnMarker
@onready var _feedback_label: Label3D = %FeedbackLabel


func _ready() -> void:
	_feedback_label.hide()
	_area.body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group(player_group):
		return
	PlayerProfile.heal_party()
	var level_path: String = get_tree().current_scene.scene_file_path
	PlayerProfile.set_respawn_point(RespawnPoint.from_marker(level_path, _respawn_marker.global_transform))
	_show_feedback()
	party_healed.emit()


func _show_feedback() -> void:
	if _feedback_tween != null:
		_feedback_tween.kill()
	_feedback_label.text = feedback_text
	_feedback_label.modulate.a = 1.0
	_feedback_label.show()
	_feedback_tween = create_tween()
	_feedback_tween.tween_property(_feedback_label, "modulate:a", 0.0, feedback_duration)
	_feedback_tween.tween_callback(_feedback_label.hide)
