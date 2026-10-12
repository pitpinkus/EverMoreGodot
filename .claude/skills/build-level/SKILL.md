---
name: build-level
description: Create or extend a map / level / world area scene in Evermore (Godot 4.7) — terrain or tiles, spawn points, level bounds, camera limits, and placement of instanced props and characters. Use when the user asks for a new map, level, room, area or world section.
---

# Build a level

A level is a **composition of prefabs**. It owns layout and wiring only; it should contain almost no logic of its own.

## 1. Check what exists
- `Glob res://levels/**/*.tscn` — is there a `level_base.tscn` to inherit from? (If not and this is the first level, create it in step 2.)
- `Glob res://prefabs/**/*.tscn` — list props and characters you can place. Anything missing gets built with `build-prop` / `build-character` first, **as a prefab**, then instanced here.

## 2. Level base (create once, then inherit)
`res://levels/level_base/level_base.tscn` + `level_base.gd` (`class_name Level`). Every level is an **inherited scene** of it.

```
Level (Node3D)                 level_base.gd
├── Environment                WorldEnvironment (shared .tres environment) + DirectionalLight3D
├── Terrain (Node3D)           GridMap (shared MeshLibrary) / MeshInstance3D + StaticBody3D; CSG only for blockout
├── NavigationRegion3D         baked navmesh for NPCs / wandering creatures
├── Props (Node3D)             instanced prop prefabs
├── Characters (Node3D)        instanced NPC / trainer / creature prefabs
├── EncounterZones (Node3D)    instanced encounter_zone prefabs (tall grass, caves...) with an @export EncounterTable resource
├── SpawnPoints (Node3D)       Marker3D children, e.g. PlayerSpawn
└── Triggers (Node3D)          Area3D-based trigger prefabs (exits, cutscene zones)
```
`level_base.gd` exports: `level_id: StringName`, `music: AudioStream`, and exposes `get_spawn(name) -> Transform3D`. It emits `level_ready` after setup. The player is **not** saved inside the level; the game/level loader instances it at a spawn point.

## 3. Build the new level
1. Create `res://levels/<level_name>/<level_name>.tscn` inheriting `level_base.tscn`.
2. Terrain: reuse the shared `MeshLibrary` / environment resources in `res://assets/` (shared by all levels, R1). Collision lives on the meshes/library, not added per level.
3. Wild encounters: place `encounter_zone` prefabs; which creatures appear (and at what rate/level) is an `EncounterTable` resource in `res://data/encounters/`, never hard-coded in the level.
4. Place props and characters **only as instances** under their group nodes. Configure them via their `@export` values; don't edit their internals in the level (no "Editable Children" changes unless it's the only option).
5. Add a `PlayerSpawn` marker and any named spawns used by exits/doors.
6. Connect level exits via a reusable `level_exit` trigger prefab with `@export target_level: String` and `@export target_spawn: StringName`.
7. Rebake the `NavigationRegion3D` after layout changes.
8. Migrating a Unity scene: read the Unity `.unity` scene / prefabs for layout and content, then rebuild with Godot prefabs. Don't import Unity scene files.

## 4. Done checklist
- [ ] Inherits `level_base.tscn`.
- [ ] Every repeated object is an instanced prefab (R2), no inline duplicates.
- [ ] No logic in the level script beyond wiring; behaviour lives in prefabs/components.
- [ ] Has `PlayerSpawn`; exits point at existing levels/spawns.
- [ ] Encounters come from `EncounterTable` resources (R6).
- [ ] Collision layers/masks use the named layers in Project Settings (`layer_names/3d_physics`); add names there if missing.
