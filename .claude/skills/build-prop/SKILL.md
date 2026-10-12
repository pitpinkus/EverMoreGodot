---
name: build-prop
description: Create a reusable non-character object prefab for Evermore (Godot 4.7) — platforms (static, moving, falling, one-way), doors, chests, pickups/collectibles, hazards, switches, triggers, breakables, checkpoints. Use for any world object that isn't a map and isn't a living character.
---

# Build a prop

Every prop is a **self-contained prefab**: a flat file `res://prefabs/props/<prop_name>.tscn`, plus `res://scripts/props/<prop_name>.gd` if it needs code (R11, same base name, no per-prop folder). It must work when dropped into any level.

## 1. Check what exists
- `Glob res://prefabs/props/*.tscn` — is there a prop this is a variant of? Then make an **inherited scene** or reuse it with different `@export` values (R2). A "moving platform" is `platform` + a `PathMover`/`Mover` component, not a new platform.
- `Glob res://scripts/components/*.gd` and `res://prefabs/components/*.tscn` — reuse components: `InteractableComponent`, `HealthComponent` (breakables), `HitboxComponent` (hazards), `Mover` (moving things), `Pickup`...

## 2. Choose the root
| Prop kind | Root |
|---|---|
| Solid, never moves (rock, sign, chest) | `StaticBody3D` |
| Moves on its own (platform, door, elevator) | `AnimatableBody3D` |
| Physics-driven (crate, ball) | `RigidBody3D` |
| Detects only (pickup, trigger, encounter zone, healing spot) | `Area3D` |

## 3. Structure
```
PropName (root body/area)       scripts/props/prop_name.gd (only if it has behaviour)
├── Model                        MeshInstance3D or an instanced imported model scene (.glb)
├── CollisionShape3D             shape resource saved as sub_resource, sized via @export where it varies
├── <Components>                 InteractableComponent, HealthComponent, Mover, ...
└── AnimationPlayer / audio      if needed
```
- Behaviour shared with other props → a component (`res://scripts/components/`, scene in `res://prefabs/components/` if needed) (R3), not code in the prop script.
- Configurable values (`@export`): size, speed, item given, damage, `one_way`, etc. No magic numbers (R6).
- Materials → `res://materials/*.tres`, shared between props instead of per-prop sub_resources when reused (R1, R11).
- Item / loot content → `ItemData` Resource (class in `res://scripts/resources/item_data.gd`, content in `res://data/items/*.tres`); the pickup prefab has `@export var item: ItemData`.
- Emit signals for things the world cares about (`opened`, `collected`, `activated`, `destroyed`); never reach into the level or player with paths (R4). To find the player, use groups (`"player"`) or the body that entered.
- Set collision layer/mask using the named physics layers in Project Settings.
- Player interaction (open, talk, pick up, flip a switch) goes through `InteractableComponent` and an InputMap action with keyboard and joypad bindings — never mouse-click-only or hover-only (R7, R12).

## 4. Variants
Variants are inherited scenes, flat in the same folder: `prefabs/props/platform.tscn` → `prefabs/props/platform_moving.tscn`, `platform_falling.tscn`. A variant overrides exports or adds a component; it never copies the base's nodes. It only gets its own script (`scripts/props/platform_moving.gd`) if it really adds behaviour.

## 5. Done checklist
- [ ] Scene is `res://prefabs/props/<name>.tscn` (flat, no subfolder); script, if any, is `res://scripts/props/<name>.gd` (R11).
- [ ] Works standalone in an empty scene (R2).
- [ ] Reuses existing components; no logic duplicated from another prop (R1).
- [ ] Variants are inherited scenes (R2).
- [ ] All tunables exported; content in Resources (R6).
- [ ] Talks outward only via signals / groups (R4).
- [ ] Interactions work through actions with keyboard and joypad bindings (R7, R12).
