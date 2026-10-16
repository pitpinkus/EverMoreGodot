class_name OptionalScene
extends RefCounted
## Static helper for optional prefabs loaded by path (e.g. the screen fade, the
## portrait studio): the game keeps working without them.


## Instances the scene at path, adds it to parent and returns it, if its root is an
## instance of expected (a class_name script). Otherwise returns null: with a warning
## when the file exists but is not usable, and also when it is missing if warn_if_missing.
static func add_to(parent: Node, path: String, expected: Script, warn_if_missing: bool = false) -> Node:
	if not ResourceLoader.exists(path):
		if warn_if_missing:
			push_warning("%s: optional scene '%s' is missing." % [parent.name, path])
		return null
	var scene: PackedScene = load(path) as PackedScene
	var root: Node = scene.instantiate() if scene != null else null
	if root == null or not is_instance_of(root, expected):
		push_warning("%s: '%s' is not a %s scene." % [parent.name, path, expected.get_global_name()])
		if root != null:
			root.free()
		return null
	parent.add_child(root)
	return root
