class_name OneShotVfx
extends Node3D
## A particle burst that plays once where it is spawned and then frees itself (cast
## flash, impact, heal burst, ...). Every GPUParticles3D / CPUParticles3D below it is
## restarted as one-shot when it enters the tree. Spawned by ActionVfxPlayer.

## Time until the node is freed; at least the longest particle lifetime.
@export_range(0.1, 10.0, 0.05, "suffix:s") var lifetime: float = 1.5


func _ready() -> void:
	for node: Node in find_children("*", "GPUParticles3D"):
		var gpu_particles: GPUParticles3D = node as GPUParticles3D
		gpu_particles.one_shot = true
		gpu_particles.restart()
	for node: Node in find_children("*", "CPUParticles3D"):
		var cpu_particles: CPUParticles3D = node as CPUParticles3D
		cpu_particles.one_shot = true
		cpu_particles.restart()
	get_tree().create_timer(lifetime, false).timeout.connect(queue_free)
