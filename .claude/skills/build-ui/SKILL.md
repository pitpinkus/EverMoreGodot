---
name: build-ui
description: Create UI for Evermore (Godot 4.7) — menus, buttons, HUD, dialog/conversation boxes, popups, confirmation dialogs, settings screens, tooltips, inventory panels. Use whenever the task is a screen or UI widget.
---

# Build UI

UI is built from **reusable widget prefabs** styled by **one shared theme**.

## 1. Check what exists
- `res://ui/theme/main_theme.tres` — if missing, create it first (step 2).
- `Glob res://prefabs/ui/*.tscn` — reuse existing widgets (button, panel, popup, dialog box...).
- `Glob res://ui/screens/*.tscn` — similar screens to inherit from.
- `Glob res://scripts/ui/*.gd` — existing UI scripts.

## 2. Theme (create once)
`res://ui/theme/main_theme.tres`, set as the project default (`gui/theme/custom` in `project.godot`). It defines: default font + sizes, `Button` normal/hover/pressed/focus/disabled styleboxes, a clearly visible `focus` stylebox for every focusable type used (`Button`, `CheckBox`, `OptionButton`, `Slider`, `LineEdit`, `ItemList`...) (R12), `Panel`/`PanelContainer` stylebox, `Label` colors. Variations (e.g. `TitleLabel`, `DangerButton`) are **theme type variations**, applied via `theme_type_variation` — not overrides on the node (R8).

## 3. Widgets → `res://prefabs/ui/<widget>.tscn`
Flat files, no per-widget folder; a widget's script is `res://scripts/ui/<widget>.gd` (same base name, R11). Make a widget a prefab as soon as it appears twice or is obviously generic. Typical set:

| Prefab | Root | Notes |
|---|---|---|
| `menu_button` | `Button` | plays hover/click sound via a shared `UiSfx` autoload or component |
| `popup_base` | `PopupPanel` or `Control` + dimmer | `open()` / `close()`, emits `closed`, pauses input underneath, Esc / `ui_cancel` closes |
| `confirm_popup` | inherits `popup_base` | `@export` title/message/confirm text, emits `confirmed` / `cancelled` |
| `dialog_box` | `PanelContainer` | conversation box: speaker name, portrait, typewriter text, choices list; driven by a `DialogLine` / `Dialog` Resource (classes in `res://scripts/resources/`, content in `res://data/dialog/`) |
| `hud_bar` | `HBoxContainer` + `TextureProgressBar` | health/mana etc., listens to a component's `*_changed` signal |
| `tooltip` | `PanelContainer` | shown on `focus_entered` as well as hover (R12) |

Prefer Godot's built-ins (`AcceptDialog`, `ConfirmationDialog`, `PopupMenu`, `OptionButton`) when they fit; wrap them in a prefab only to add shared styling/behaviour.

## 4. Screens → `res://ui/screens/<screen>.tscn`
Main menu, pause, settings, HUD, game over... Flat files; the screen script is `res://scripts/ui/<screen>.gd` (R11). Each screen:
- Root `Control` with full-rect anchors; layout via `MarginContainer` → `VBoxContainer`/`HBoxContainer`/`GridContainer`. **No absolute positions** (R8).
- Built from widget prefabs (instanced).
- Screen script only wires buttons to signals or `EventBus` calls (e.g. `start_game_requested`). It does not load levels or change game state directly (R4).
- Shared screen behaviour (fade in/out, back button handling) lives in a `screen_base` scene that screens inherit.

## 5. UX requirements
- Keyboard and controller (R12) — every screen/popup must work with keyboard only, gamepad only, and mouse:
  - **Initial focus:** on open/show, the default control calls `grab_focus()` (put this in `screen_base` / `popup_base`, with an `@export var initial_focus: Control`, not in every screen, R1). When a popup closes, focus returns to the control that opened it.
  - **Focus order:** containers give the order; set `focus_neighbor_*` / `focus_next` / `focus_previous` where they don't (grids, side panels, wrap-around lists). Focus never lands on a hidden or disabled control, and never gets stuck.
  - **Actions:** `ui_accept` activates, `ui_cancel` goes back/closes. Tabs/pages switch with actions that have both key and joypad bindings (R7, R12).
  - **No mouse-only interactions:** anything shown on hover also shows on focus; drag-and-drop has a select-then-confirm alternative; scroll containers follow focus (`follow_focus = true`).
  - **Interactive controls keep `focus_mode = FOCUS_ALL`**; decorative ones use `FOCUS_NONE`. Mouse hover/click keeps working.
- Visible focus state comes from the theme's `focus` styleboxes (R8, R12), not per-node overrides.
- Text from exports or data, not hard-coded in scripts; leave room for longer translated strings (use `autowrap`, don't fix label widths).
- Test at the project's stretch settings (`canvas_items`, `expand`): layout must hold at 16:9 and 4:3.

## 6. Done checklist
- [ ] Widgets in `res://prefabs/ui/`, screens in `res://ui/screens/`, their scripts in `res://scripts/ui/` with matching base names (R11).
- [ ] Only theme + type variations for styling (R8).
- [ ] Repeated widgets are prefabs in `res://prefabs/ui/` (R2).
- [ ] Containers/anchors only, no hand-placed positions.
- [ ] Works with keyboard only, gamepad only, and mouse: initial focus grabbed on open, sensible focus neighbours, `ui_accept` / `ui_cancel` work (R12).
- [ ] No hover-only info or drag-only controls; focus visible via theme `focus` styleboxes (R8, R12).
- [ ] Popups close on `ui_cancel`, emit a signal when closed, and return focus to the opener (R12).
