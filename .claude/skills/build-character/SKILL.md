---
name: build-character
description: Create a player, NPC, trainer or creature for Evermore (Godot 4.7, 3D) — body, model, animations, stats, state machine, AI, interaction and dialog hooks, and creature species/instance data. Use whenever the task is a living character or creature of any kind.
---

# Build a character

All characters share **one base prefab** and are differentiated by **components**, **state machines** and **data resources**. Never write a second movement/health/animation system.

## 1. Check what exists
- `res://prefabs/characters/character_base.tscn` — create it first if missing (step 2).
- `Glob res://prefabs/characters/*.tscn` — maybe this is a variant of an existing character (e.g. a guard is an `npc` with a different `CharacterData` and a patrol state).
- `Glob res://scripts/components/*.gd`, `res://scripts/characters/*.gd`, `res://scripts/resources/*.gd` and `res://data/characters/**`.

## 2. Character base (create once)
`res://prefabs/characters/character_base.tscn` + `res://scripts/characters/character_base.gd` (`class_name Character`) (R11):
```
Character (CharacterBody3D)    scripts/characters/character_base.gd — movement API only: move(direction), stop(), face(dir)
├── Visual                     empty Node3D in the base; variants instance a model prefab here
├── CollisionShape
├── HealthComponent            emits health_changed, died
├── HurtboxComponent           receives damage → HealthComponent
├── (variant) StateMachine     added by variants (e.g. player.tscn), not the base; child State nodes, each its own script; emits state_changed(from, to)
├── (variant) AnimationComponent  added by variants alongside StateMachine; prefabs/components/animation_component.tscn
└── (optional) NavigationAgent, InteractableComponent, HitboxComponent
```
- **Models are separate visual prefabs** (e.g. `prefabs/characters/earth_traveler_model.tscn`): an imported or primitive-built model plus its own `AnimationPlayer`. `character_base.tscn` has no model and no AnimationPlayer of its own; a variant instances a model prefab under `Visual`. Reuse an existing model prefab before making a new one (R1, R2).
- **Imported models:** a wrapper prefab in `prefabs/characters/` instances the asset from `res://assets/` (e.g. `assets/characters/earth_traveler/earth_traveler.gltf`), rotates it to face -Z, and applies toon materials via `surface_material_override`. Name the clips after the state names; a `_loop` suffix in the source file makes Godot import the clip as looping and strips the suffix.
- **Toon materials:** each surface colour is a `ShaderMaterial` `.tres` in `res://materials/` using `res://materials/shaders/toon_lit.gdshader`, setting only `shader_parameter/albedo` (optionally `albedo_texture`, `specular_amount`, `rim_amount`). Body materials set `rim_amount = 1.0`; small details such as eyes leave it at 0. Reuse an existing material before adding one (R1). Character and creature materials set `next_pass = res://materials/toon_outline.tres` (inverted-hull outline). Shared look tunables are the `toon_*` global uniforms in `project.godot` `[shader_globals]`; never hard-code them in a material (R6). Shaders live only in `res://materials/shaders/`.
- **Animation is driven by `AnimationComponent`**, which is model-agnostic: in the character scene, connect `StateMachine.state_changed(from, to)` to its `_on_state_changed` and set its `animation_player` export to the model's `AnimationPlayer`. It plays the animation named like the new state; use its `animation_overrides` Dictionary (state name → animation name) when names differ, and its `blend_time` export for cross-fades.
- `@export var data: CharacterData` — a `Resource` (class in `res://scripts/resources/character_data.gd`, instances in `res://data/characters/*.tres`) with name, portrait, max_health, speed, faction, etc. **All stats come from here** (R6).
- `StateMachine` + `State` base class live in `res://scripts/components/` (`state_machine.gd`, `state.gd`) and are shared by player, NPCs and enemies. Individual state scripts go in `res://scripts/characters/` (or `scripts/components/` if not character-specific).

## 3. Variants (inherited scenes of character_base)
All variants are flat files in `res://prefabs/characters/`; a variant only gets a script (`res://scripts/characters/<variant>.gd`, same base name) if it adds behaviour (R11).

| Variant | Scene | Adds |
|---|---|---|
| Player | `prefabs/characters/player.tscn` | `PlayerInputComponent` (`scripts/components/player_input_component.gd`; reads InputMap actions, R7) that drives the base movement API; camera; added to group `"player"` |
| NPC | `prefabs/characters/npc.tscn` | `InteractableComponent` + `@export var dialog: Dialog` (opens the `dialog_box` UI via `EventBus`); idle/wander/patrol states |
| Trainer | `prefabs/characters/trainer.tscn` | inherits `npc`; line-of-sight `Area3D`, `@export var party: Array[CreatureInstance]`, starts a battle via `EventBus` |
| Wild creature (overworld) | `prefabs/characters/creature.tscn` | wander/flee/approach states; `@export var species: CreatureSpecies`; touching it starts a battle |

**Creatures in battle are data, not character scenes.** A creature's species (base stats, types, learnable moves, model) is a `CreatureSpecies` resource; an owned/encountered creature is a `CreatureInstance` resource (level, current HP, moves, status). Moves and status effects (burn, ...) are their own Resources (classes in `res://scripts/resources/`, content in `res://data/`). The battle scene shows them with a shared `battle_creature` prefab. When migrating, map the Unity ScriptableObjects/classes to these resources.

A specific character (e.g. "Blacksmith", "Slime") is usually **just a `.tres` CharacterData + an instance of the variant**. Make a new inherited scene only if it needs different nodes (new visual, extra component). Character-specific logic is a new `State` or component, never a fork of an existing script.

## 4. Rules for character code
- Input only in the `PlayerInputComponent`; AI only in states. It reads actions only, so keyboard and gamepad behave the same; analog actions (move, camera) use `Input.get_vector()` / `get_axis()` so sticks get proportional input. Mouse look is an extra on top of the camera actions, never the only way (R7, R12). The base script knows nothing about either.
- States contain **no animation code**: name states after their animation (or add an `animation_overrides` entry) and let `AnimationComponent` play it. No `play()` calls in states, character scripts or other components.
- Characters announce events via signals (`died`, `interacted`, `attacked`). Global reactions (quest progress, score, dialog UI) go through `EventBus` (R4).
- Dialog content lives in `Dialog` / `DialogLine` Resources in `res://data/dialog/`, shared with the `dialog_box` UI prefab (see `build-ui`).

## 5. Done checklist
- [ ] Scene is a flat file in `res://prefabs/characters/`; scripts in `res://scripts/characters/` (or `scripts/components/`, `scripts/resources/`) with matching base names (R11).
- [ ] Inherits `character_base` (directly or via player/npc/enemy) (R2).
- [ ] Stats from `CharacterData` resource; no hard-coded numbers (R6).
- [ ] Reuses shared components and `StateMachine`; no duplicated movement/health/AI code (R1, R3).
- [ ] Model is an instanced model prefab under `Visual`; animation only via `AnimationComponent` wired to `state_changed`, no `play()` in states (R1, R2, R3, R4).
- [ ] Surface materials are `toon_lit` ShaderMaterials in `res://materials/` (only albedo / albedo_texture / specular_amount / rim_amount set; `rim_amount = 1.0` on body materials, 0 on small details like eyes) with `next_pass = toon_outline.tres`; existing ones reused; no `toon_*` global tunables hard-coded (R1, R6, R11).
- [ ] Player input via actions only (R7); every action used has keyboard and joypad bindings, nothing mouse-only (R12).
- [ ] Works when instanced into any level (no paths to level nodes).
