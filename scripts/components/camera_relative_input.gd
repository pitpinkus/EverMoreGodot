class_name CameraRelativeInput
extends RefCounted
## Static helper: turns 2D stick/WASD input into a flat world direction relative to a
## camera (or any pivot), so "up" always means "away from the camera".


## input: x = right, y = back (as from Input.get_vector(left, right, forward, back)).
## Keeps analog magnitude; zero if pivot is null.
static func to_world(input: Vector2, pivot: Node3D) -> Vector3:
	if pivot == null or input.is_zero_approx():
		return Vector3.ZERO
	var basis: Basis = pivot.global_basis
	var right: Vector3 = Vector3(basis.x.x, 0.0, basis.x.z).normalized()
	var back: Vector3 = Vector3(basis.z.x, 0.0, basis.z.z).normalized()
	return right * input.x + back * input.y
