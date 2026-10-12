---
name: build-ui
description: Create UI for Evermore (Godot 4.7) — menus, buttons, HUD, dialog/conversation boxes, popups, confirmation dialogs, settings screens, tooltips, inventory panels. Use whenever the task is a screen or UI widget.
---

# Build UI

UI is built from **reusable widget prefabs** styled by **one shared theme**.

## 1. Check what exists
- `res://ui/theme/main_theme.tres` — if missing, create it first (step 2).
- `Glob res://prefabs/ui/**/*.tscn` — reuse existing widgets (button, panel, popup, dialog box...).
- `Glob res://ui/screens/**/*.tscn` — similar screens to inherit from.

## 2. Theme (create once)
`res://ui/theme/main_theme.tres`, set as the project default (`gui/theme/custom` in `project.godot`). It defines: default font + sizes, `Button` normal/hover/pressed/focus/disabled styleboxes, `Panel`/`PanelContainer` stylebox, `Label` colors. Variations (e.g. `TitleLabel`, `DangerButton`) are **theme type variations**, applied via `theme_type_variation` — not overrides on the node (R8).

## 3. Widgets → `res://prefabs/ui/<widget>/`
Make a widget a prefab as soon as it appears twice or is obviously generic. Typical set:

| Prefab | Root | Notes |
|---|---|---|
| `menu_button` | `Button` | plays hover/click sound via a shared `UiSfx` autoload or component |
| `popup_base` | `PopupPanel` or `Control` + dimmer | `open()` / `close()`, emits `closed`, pauses input underneath, Esc / `ui_cancel` closes |
| `confirm_popup` | inherits `popup_base` | `@export` title/message/confirm text, emits `confirmed` / `cancelled` |
| `dialog_box` | `PanelContainer` | conversation box: speaker name, portrait, typewriter text, choices list; driven by a `DialogLine` / `Dialog` Resource in `res://data/dialog/` |
| `hud_bar` | `HBoxContainer` + `TextureProgressBar` | health/mana etc., listens to a component's `*_changed` signal |
| `tooltip` | `PanelContainer` | |

Prefer Godot's built-ins (`AcceptDialog`, `ConfirmationDialog`, `PopupMenu`, `OptionButton`) when they fit; wrap them in a prefab only to add shared styling/behaviour.

## 4. Screens → `res://ui/screens/<screen>/`
Main menu, pause, settings, HUD, game over... Each screen:
- Root `Control` with full-rect anchors; layout via `MarginContainer` → `VBoxContainer`/`HBoxContainer`/`GridContainer`. **No absolute positions** (R8).
- Built from widget prefabs (instanced).
- Screen script only wires buttons to signals or `EventBus` calls (e.g. `start_game_requested`). It does not load levels or change game state directly (R4).
- Shared screen behaviour (fade in/out, back button handling) lives in a `screen_base` scene that screens inherit.

## 5. UX requirements
- Keyboard and gamepad: first focusable control calls `grab_focus()` on show; `focus_neighbor_*` set where containers don't give a sensible order; `ui_cancel` goes back/closes.
- Visible focus state in the theme.
- Text from exports or data, not hard-coded in scripts; leave room for longer translated strings (use `autowrap`, don't fix label widths).
- Test at the project's stretch settings (`canvas_items`, `expand`): layout must hold at 16:9 and 4:3.

## 6. Done checklist
- [ ] Only theme + type variations for styling (R8).
- [ ] Repeated widgets are prefabs in `res://prefabs/ui/` (R2).
- [ ] Containers/anchors only, no hand-placed positions.
- [ ] Works with keyboard/gamepad only.
- [ ] Popups close on `ui_cancel` and emit a signal when closed.
