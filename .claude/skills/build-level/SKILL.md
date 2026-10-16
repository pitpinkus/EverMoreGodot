---
name: build-level
description: Create or extend a map / level / world area scene in Evermore (Godot 4.7) — terrain or tiles, spawn points, level bounds, camera limits, and placement of instanced props and characters. Use when the user asks for a new map, level, room, area or world section.
---

# Build a level

A level is a **composition of prefabs**. It owns layout and wiring only; it should contain almost no logic of its own.

## 1. Check what exists
- `Glob res://levels/*.tscn` — is there a `level_base.tscn` to inherit from? (If not and this is the first level, create it in step 2.)
- `Glob res://prefabs/*/*.tscn` — list props and characters you can place. Anything missing gets built with `build-prop` / `build-character` first, **as a prefab**, then instanced here.

## 2. Level base (create once, then inherit)
`res://levels/level_base.tscn` + `res://scripts/levels/level_base.gd` (`class_name Level`) (R11). Every level is an **inherited scene** of it.

```
Level (Node3D)                 scripts/levels/level_base.gd
├── EnvironmentRig             instance of prefabs/props/environment_rig.tscn: WorldEnvironment (materials/default_environment.tres),
│                              EnvironmentSettingsComponent, Sun (DirectionalLight3D), ScreenInkOutline (screen-space toon outline)
├── Terrain (Node3D)           GridMap (shared MeshLibrary) / MeshInstance3D + StaticBody3D; CSG only for blockout
├── Props (Node3D)             instanced prop prefabs, incl. tall_grass and heal_point
├── %Characters (Node3D)       instanced NPC prefabs and encounter NPCs (trainer, wild_monster)
├── %SpawnPoints (Node3D)      Marker3D children, e.g. PlayerSpawn
└── UI (CanvasLayer)
    ├── PauseMenu              ui/screens/pause_menu.tscn
    └── InventoryScreen        ui/screens/inventory_screen.tscn; must stay AFTER PauseMenu: later siblings get
                               _unhandled_input first, so an open inventory consumes Esc/cancel before the pause menu
```
Future (not in the base yet, add to `level_base.tscn` only when a feature first needs it, R10): `NavigationRegion3D` (baked navmesh for wandering NPCs) and `Triggers (Node3D)` (exits, cutscene zones).
`level_base.gd` exports: `level_id: StringName`, `music: AudioStream`, and exposes `get_spawn(name) -> Transform3D`. It emits `level_ready` after setup. (These members are the target API: add each one to `level_base.gd` when a feature first needs it, not up front, R10.) The player is **not** saved inside the level; the game/level loader instances it at a spawn point.

## 3. Build the new level
1. Create `res://levels/<level_name>.tscn` (flat, no per-level folder, R11) inheriting `level_base.tscn`. It only gets a script (`res://scripts/levels/<level_name>.gd`) if it needs level-specific wiring.
2. Terrain: reuse the shared `MeshLibrary` and the shared materials / environment `.tres` in `res://materials/` (shared by all levels, R1, R11). Collision lives on the meshes/library, not added per level. New surface colours follow the toon material recipe in `build-prop` (`toon_lit` ShaderMaterial, `rim_amount` left at 0); terrain gets no `next_pass` hull, since the ink outline comes from `level_base` (don't add a second one). Look tunables are `toon_*` globals in `project.godot` `[shader_globals]`, not per-material values (R6).
3. Encounters: every battle starts from an `EncounterTrigger` (`prefabs/components/encounter_trigger.tscn`). Place its variant `prefabs/props/tall_grass.tscn` (random encounters while walking; set `size`) under `Props`, and `prefabs/characters/trainer.tscn` / `wild_monster.tscn` (start on contact or line of sight; see `build-character`) under `Characters`. Set each instance's `encounter` to an `Encounter` resource in `res://data/encounters/` (`RandomEncounter`: one monster from a weighted `table`, e.g. grass; `FixedEncounter`: a set `team`, e.g. a trainer or a specific wild monster; `is_wild` and optional `battle_map` on both); give one-time fights a unique `encounter_id`. Which monsters appear, at what rate and level, is never hard-coded in the level (R6).
4. Place at least one `prefabs/props/heal_point.tscn` under `Props`: it heals the party and sets the respawn point after a lost battle.
5. Place props and characters **only as instances** under their group nodes. Configure them via their `@export` values; don't edit their internals in the level (no "Editable Children" changes unless it's the only option).
6. Add a `PlayerSpawn` marker and any named spawns used by exits/doors.
7. (Future, when exits exist) Connect level exits via a reusable `level_exit` trigger prefab with `@export target_level: String` and `@export target_spawn: StringName`.
8. (Future, once the level has a `NavigationRegion3D`) Rebake it after layout changes.
9. Migrating a Unity scene: read the Unity `.unity` scene / prefabs for layout and content, then rebuild with Godot prefabs. Don't import Unity scene files.

## 4. Done checklist
- [ ] Scene is `res://levels/<level_name>.tscn`; any script is `res://scripts/levels/<level_name>.gd`; materials/environment in `res://materials/` (R11).
- [ ] Inherits `level_base.tscn` (R2), so it gets the screen ink outline; no extra outline instance or hull materials (R1).
- [ ] Every repeated object is an instanced prefab (R2), no inline duplicates.
- [ ] No logic in the level script beyond wiring; behaviour lives in prefabs/components.
- [ ] Has `PlayerSpawn`; exits point at existing levels/spawns.
- [ ] Encounters come from `tall_grass` / `trainer` / `wild_monster` instances (`EncounterTrigger` based) with `Encounter` resources from `res://data/encounters/`; no new trigger scripts (R1, R2, R6).
- [ ] Collision layers/masks use the named layers in Project Settings (`layer_names/3d_physics`); add names there if missing.
