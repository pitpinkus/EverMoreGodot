# Evermore — Godot 4.7 project

Engine: Godot 4.7 (Forward Plus, Jolt Physics). Language: GDScript.
Game type: **3D turn-based creature-collecting RPG** (Pokémon-like): explore a 3D overworld, meet and catch creatures, fight turn-based battles with moves, status effects (burn, ...) and abilities.

## This is a remake of a Unity game
Evermore is a Godot remake of our earlier Unity project **"Evermore – the Wilds"**:
- Local copy: `C:\Users\Pinkus\source\repos\Evermore--the-wilds` (Unity 6000.3, C#, game code under `Assets/MainAssets`, `Assets/Scenes`, `Assets/Resources`)
- Remote: https://github.com/Shacharh/Evermore--the-wilds

Much of the work is migration. When porting a feature:
- **Read the Unity C# first** to understand the behaviour and data (creatures, moves, effects, stats), then **redesign it the Godot way**. Don't translate line by line.
- Fix the old code's problems instead of copying them: duplication, hard-coded values, MonoBehaviours doing too much. The rules below apply to migrated code too.
- Unity ScriptableObjects → custom `Resource` + `.tres`. MonoBehaviour components → component nodes. Unity events / singletons → signals / autoloads.
- The Unity project is **read-only reference**: never edit or commit anything in it.

## Team (subagents in `.claude/agents/`)

| Agent | Role |
|---|---|
| `game-architect` | Plans features that touch more than one system: which prefabs, components, resources and autoloads are needed, and what already exists to reuse. Writes no code. |
| `gameplay-programmer` | Writes GDScript: game logic, components, autoloads, resources. |
| `scene-designer` | Builds `.tscn` scenes: levels, UI, props, characters, node trees, layout. Uses the `build-*` skills. |
| `rules-guardian` | QA. Read-only. Checks every change against the rules below and returns PASS / FAIL with a list of violations. |
| `playtester` | Runs Godot headless to catch parse errors, broken references and runtime errors. |
| `ai-team-manager` | Owns the AI team itself: creates, edits and retires agents and skills, and keeps this file's Team / Workflow / Rules sections in sync. All changes to `.claude/agents/` and `.claude/skills/` go through it. |
| `git-operator` | The only agent that changes git state: check-in (add/commit/push), checkout, branches, pulls, merges. Uses the `git-checkin` / `git-checkout` skills. Other agents may only run read-only git commands. |

## Workflow (the main session orchestrates)

Follow the `feature-pipeline` skill for any non-trivial change. In short:

1. Big feature → `game-architect` makes a plan first.
2. `gameplay-programmer` and/or `scene-designer` implement.
3. `rules-guardian` reviews. On FAIL, send the exact violations back to the agent that made the change (SendMessage, so it keeps its context) and review again.
4. **After 3 FAILs on the same task, stop and ask the user what to do** (AskUserQuestion), showing the remaining violations.
5. On PASS → `playtester` checks the project loads and runs. Errors go back to step 2 (they count toward the same 3-attempt limit).

## Global rules

Every agent must follow these. `rules-guardian` cites them by ID.

### R1 — No duplicated code
- Before writing anything, search the project (Grep/Glob) for existing scripts, components, prefabs and helpers that already do it. Reuse or extend them.
- Logic needed in two places goes in one shared place: a component node, a base class (`class_name`), a static helper, a `Resource`, or an autoload.
- No copy-pasted blocks (roughly 5+ similar lines) and no near-identical scripts that differ only in values. Values that differ belong in `@export` vars or `.tres` data.

### R2 — Reusable nodes are prefabs
- Any node tree that is used more than once, or is clearly meant to be (props, characters, UI widgets, pickups, hazards), is saved as its own scene in `res://prefabs/<category>/` (see R11) and **instanced**, never rebuilt by hand or copied.
- Variants (e.g. "moving platform" from "platform", "merchant" from "npc") are **inherited scenes** or the same prefab with different `@export` values / data resources. Not copies.
- Prefabs must be self-contained: they work when dropped into any scene, and they don't reach into their parent with `get_parent()` or `../` paths.

### R3 — Composition over inheritance
Behaviour is split into small component nodes (`HealthComponent`, `HitboxComponent`, `InteractableComponent`, `StateMachine`, ...): scripts in `res://scripts/components/`, scenes (if any) in `res://prefabs/components/` (R11). Deep inheritance chains (more than 2 levels of your own classes) need a reason.

### R4 — Signals up, calls down
- A node may call methods on its children. It talks to parents and siblings through **signals**.
- No `get_node("../../X")`, no hard-coded absolute paths like `/root/Main/Player`. Use `@export var x: NodeType`, `%UniqueName`, groups, or an autoload event bus.

### R5 — Static typing and naming
- Typed GDScript everywhere: `var speed: float = 200.0`, `func hit(amount: int) -> void:`, typed arrays `Array[Item]`.
- Files and folders: `snake_case` (`moving_platform.tscn`, `health_component.gd`). Node names and `class_name`: `PascalCase`. Constants: `UPPER_SNAKE_CASE`. Signals: past tense (`died`, `health_changed`).
- A scene and its root script share the same snake_case base name; the script lives under `res://scripts/<domain>/` (`prefabs/props/door.tscn` ↔ `scripts/props/door.gd`). See R11.

### R6 — Data out of code
No magic numbers or hard-coded content. Tunables are `@export` vars or `const`. Stats, items, dialog lines and similar content live in custom `Resource` classes (`.tres` files in `res://data/`).

### R7 — Input through actions
Input only via InputMap actions (`Input.is_action_pressed("jump")`), never raw keycodes. New actions are added to `project.godot`.

### R8 — UI uses the shared theme
All UI uses the project theme at `res://ui/theme/main_theme.tres` and theme type variations. No per-node color, font or style overrides unless it is a one-off, and then with a comment saying why. Layout uses containers and anchors, never hand-placed pixel positions.

### R9 — Keep files valid and small
- Hand-written `.tscn` / `.tres` must be valid Godot 4 text format. Don't invent `uid://` values: write `ext_resource` entries with `path=` only and let the editor add uids.
- Never edit anything in `.godot/` and don't commit `*.import` changes by hand. Only exception: for third-party model files copied into `res://assets/models/`, an agent may write their `.import` options (import as animation library, scale, root type). Nothing in `.godot/` may be touched.
- One responsibility per script. A script over ~300 lines is a sign it should be split.

### R10 — No dead code
No commented-out code, unused variables, unused exports, or leftover `print()` debugging. Use `push_warning` / `push_error` for real problems.

### R11 — File structure by type
Files are separated by **type** into top-level folders (see Folder layout below):
- **All `.gd` files live under `res://scripts/<domain>/`** (`autoload`, `components`, `characters`, `props`, `levels`, `ui`, `resources`, `battle`, `vfx`, `editor`). No `.gd` anywhere else. Custom `Resource` class scripts go in `scripts/resources/`. `scripts/editor/` holds editor-only `@tool` code; it is never referenced by game code.
- Exception: `res://addons/<plugin>/` may contain only `plugin.cfg` and at most one entry `.gd` shim that `extends` a script in `scripts/editor/`. Third-party addons are exempt as a whole. Export presets must exclude `addons/*` and `scripts/editor/*`.
- **`.tscn` files live only in `res://prefabs/<category>/`, `res://levels/` or `res://ui/screens/`.** Prefabs and levels are **flat files** per category: `prefabs/props/block.tscn`, `levels/test_overworld.tscn`. No per-item subfolder (no `prefabs/props/block/block.tscn`).
- A scene's root script keeps the **same snake_case base name** as the scene, under the matching domain: `prefabs/props/block.tscn` ↔ `scripts/props/block.gd`, `levels/level_base.tscn` ↔ `scripts/levels/level_base.gd`. Inherited variants without their own script (e.g. `player.tscn`) are fine.
- Content/stats `.tres` go in `res://data/` (category subfolders allowed, e.g. `data/movement/`). Materials, environments and other visual `.tres` go in `res://materials/`. The theme stays in `res://ui/theme/`.
- **Shader files (`.gdshader`, `.gdshaderinc`) live only in `res://materials/shaders/`.**
- Engine-generated `*.gd.uid` files stay next to their `.gd` and move with it.

### R12 — Keyboard and controller support
The game must be fully playable with keyboard (+ mouse where natural) and with a gamepad alone. Builds on R7: all input goes through InputMap actions.
- Every InputMap action in `project.godot` has at least one keyboard key binding (`InputEventKey`; mouse bindings don't count) and at least one joypad binding (`InputEventJoypadButton` / `InputEventJoypadMotion`). Mouse bindings may be added on top. Exempt: actions that only manage the mouse cursor (e.g. `capture_mouse`).
- All UI is fully navigable by keyboard and by controller: a control grabs focus when a screen or popup opens; focus order is sensible (containers, or `focus_neighbor_*` / `focus_next` / `focus_previous`); `ui_accept` activates and `ui_cancel` goes back / closes.
- No mouse-only interactions: anything shown on hover also shows on focus; no drag-only controls (give a select-then-confirm or action alternative).
- Focus is visible through the shared theme's `focus` styleboxes (R8), not per-node overrides.
- The mouse still works in menus (hover and click on the same controls).

## Git rules

### G1 — Check in before switching or leaving
If the user asks to **check out / switch a branch**, or says they're **ending the session** (exit, quit, done for today, bye...), and `git status --porcelain` shows **any** uncommitted changes: **stop and ask the user to run `/git-checkin` first.** Don't stash, discard or switch on your own. A PreToolUse hook (`.claude/hooks/guard-checkout.js`) also blocks `git checkout` / `git switch` while there are changes. A SessionStart hook warns about changes left over from an earlier session.

### G2 — Only git-operator changes git state
Commits, pushes, branches, checkouts, merges and resets go through `git-operator` or the `/git-checkin` and `/git-checkout` skills. Other agents only run `git status`, `git diff` and `git log`. No force-push and no history rewriting unless the user asks for that exact action.

## Folder layout (enforced by R11)

```
res://
  scripts/              ALL .gd files, grouped by domain
    autoload/           singletons (event_bus.gd, game_state.gd, ...)
    components/         component scripts (movement_component.gd, ...)
    characters/         character_base.gd, ...
    props/              block.gd, ...
    levels/             level_base.gd, ...
    ui/                 UI scripts (widgets and screens)
    resources/          custom Resource class scripts (movement_stats.gd, ...)
    battle/             battle logic: manager, controllers/AI, turn order, formulas
    vfx/                visual effect scripts: projectiles, one-shot particle effects, floating text
    editor/             editor-only @tool code (plugins, blueprint creator); never referenced by game code
  prefabs/              ALL reusable .tscn, flat files per category (no per-item folder)
    components/         movement_component.tscn, ...
    characters/         character_base.tscn, player.tscn, ...
    props/              block.tscn, ground_plane.tscn, ...
    ui/                 buttons, panels, dialog box, popups, ...
    vfx/                VFX prefab scenes (projectiles, particle effects, floating text, ...)
  levels/               ALL level/map .tscn, flat (level_base.tscn, test_overworld.tscn, ...)
  ui/
    screens/            screen .tscn (main menu, pause, settings, HUD, ...)
    theme/              main_theme.tres + fonts/styleboxes
  data/                 .tres content/stats (category subfolders allowed, e.g. data/movement/)
    templates/          blueprint templates; not registered in game_database
  materials/            Material / Environment / other visual .tres
    shaders/            ALL .gdshader / .gdshaderinc (toon_lit.gdshader, toon_common.gdshaderinc, ...)
  assets/               imported art, audio, fonts
    models/             imported 3D models, grouped per pack (monsters/rpg_monster_duo/, props/ghibli_nature/, ...)
  addons/               editor plugins: plugin.cfg + optional one-line shim only (R11); excluded from export
```
