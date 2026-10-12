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
├── Visual                     instanced model scene (.glb) — swapped per character via export/inheritance
├── CollisionShape
├── AnimationPlayer / AnimationTree
├── HealthComponent            emits health_changed, died
├── HurtboxComponent           receives damage → HealthComponent
├── StateMachine               child State nodes; each state is its own script
└── (optional) NavigationAgent, InteractableComponent, HitboxComponent
```
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
- Animations are chosen from state (`state.enter()` plays its animation), not scattered `play()` calls.
- Characters announce events via signals (`died`, `interacted`, `attacked`). Global reactions (quest progress, score, dialog UI) go through `EventBus` (R4).
- Dialog content lives in `Dialog` / `DialogLine` Resources in `res://data/dialog/`, shared with the `dialog_box` UI prefab (see `build-ui`).

## 5. Done checklist
- [ ] Scene is a flat file in `res://prefabs/characters/`; scripts in `res://scripts/characters/` (or `scripts/components/`, `scripts/resources/`) with matching base names (R11).
- [ ] Inherits `character_base` (directly or via player/npc/enemy) (R2).
- [ ] Stats from `CharacterData` resource; no hard-coded numbers (R6).
- [ ] Reuses shared components and `StateMachine`; no duplicated movement/health/AI code (R1, R3).
- [ ] Player input via actions only (R7); every action used has keyboard and joypad bindings, nothing mouse-only (R12).
- [ ] Works when instanced into any level (no paths to level nodes).
