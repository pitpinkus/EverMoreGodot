---
name: build-character
description: Create a player, NPC, trainer or creature for Evermore (Godot 4.7, 3D) — body, model, animations, stats, state machine, AI, interaction and dialog hooks, and creature species/instance data. Use whenever the task is a living character or creature of any kind.
---

# Build a character

All characters share **one base prefab** and are differentiated by **components**, **state machines** and **data resources**. Never write a second movement/health/animation system.

## 1. Check what exists
- `res://prefabs/characters/character_base/` — create it first if missing (step 2).
- `Glob res://prefabs/characters/**` — maybe this is a variant of an existing character (e.g. a guard is an `npc` with a different `CharacterData` and a patrol state).
- `Glob res://components/**` and `res://data/characters/**`.

## 2. Character base (create once)
`res://prefabs/characters/character_base/character_base.tscn` + `character_base.gd` (`class_name Character`):
```
Character (CharacterBody3D)    character_base.gd — movement API only: move(direction), stop(), face(dir)
├── Visual                     instanced model scene (.glb) — swapped per character via export/inheritance
├── CollisionShape
├── AnimationPlayer / AnimationTree
├── HealthComponent            emits health_changed, died
├── HurtboxComponent           receives damage → HealthComponent
├── StateMachine               child State nodes; each state is its own script
└── (optional) NavigationAgent, InteractableComponent, HitboxComponent
```
- `@export var data: CharacterData` — a `Resource` (`res://data/characters/character_data.gd`) with name, portrait, max_health, speed, faction, etc. **All stats come from here** (R6).
- `StateMachine` + `State` base class live in `res://components/state_machine/` and are shared by player, NPCs and enemies.

## 3. Variants (inherited scenes of character_base)
| Variant | Folder | Adds |
|---|---|---|
| Player | `characters/player/` | `PlayerInput` component (reads InputMap actions, R7) that drives the base movement API; camera; added to group `"player"` |
| NPC | `characters/npc/` | `InteractableComponent` + `@export var dialog: Dialog` (opens the `dialog_box` UI via `EventBus`); idle/wander/patrol states |
| Trainer | `characters/trainer/` | inherits `npc`; line-of-sight `Area3D`, `@export var party: Array[CreatureInstance]`, starts a battle via `EventBus` |
| Wild creature (overworld) | `characters/creature/` | wander/flee/approach states; `@export var species: CreatureSpecies`; touching it starts a battle |

**Creatures in battle are data, not character scenes.** A creature's species (base stats, types, learnable moves, model) is a `CreatureSpecies` resource; an owned/encountered creature is a `CreatureInstance` resource (level, current HP, moves, status). Moves and status effects (burn, ...) are their own Resources. The battle scene shows them with a shared `battle_creature` prefab. When migrating, map the Unity ScriptableObjects/classes to these resources.

A specific character (e.g. "Blacksmith", "Slime") is usually **just a `.tres` CharacterData + an instance of the variant**. Make a new inherited scene only if it needs different nodes (new visual, extra component). Character-specific logic is a new `State` or component, never a fork of an existing script.

## 4. Rules for character code
- Input only in the `PlayerInput` component; AI only in states. The base script knows nothing about either.
- Animations are chosen from state (`state.enter()` plays its animation), not scattered `play()` calls.
- Characters announce events via signals (`died`, `interacted`, `attacked`). Global reactions (quest progress, score, dialog UI) go through `EventBus` (R4).
- Dialog content lives in `Dialog` / `DialogLine` Resources in `res://data/dialog/`, shared with the `dialog_box` UI prefab (see `build-ui`).

## 5. Done checklist
- [ ] Inherits `character_base` (directly or via player/npc/enemy) (R2).
- [ ] Stats from `CharacterData` resource; no hard-coded numbers (R6).
- [ ] Reuses shared components and `StateMachine`; no duplicated movement/health/AI code (R1, R3).
- [ ] Player input via actions only (R7).
- [ ] Works when instanced into any level (no paths to level nodes).
