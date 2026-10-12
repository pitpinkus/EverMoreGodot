---
name: feature-pipeline
description: Orchestrate building a feature in Evermore with the agent team — architect plan, implementation by gameplay-programmer / scene-designer, rules-guardian QA loop (max 3 attempts, then ask the user), and playtester run. Use for any non-trivial change to the game.
---

# Feature pipeline

The main session runs this loop. Subagents do the work; you route between them and track attempts.

## 1. Plan
- Touches more than one system, or needs new components/prefabs/resources → run `game-architect` with the request. Show the user the plan briefly if it involves a real design choice.
- Small, single-file change → skip to step 2.

## 2. Implement
Send each task to the right agent with: the task, relevant plan section, and file paths.
- Code → `gameplay-programmer`
- Scenes, UI, levels, props, characters → `scene-designer` (it picks the `build-*` skill)
Independent tasks can run in parallel; dependent ones in order (usually script first, then scene).
Keep each agent's id/name so you can send feedback to the same agent later.

## 3. QA loop (attempt counter starts at 1)
1. Run `rules-guardian` with the list of changed files and which agent changed them.
2. **PASS** → go to step 4.
3. **FAIL** →
   - If attempt < 3: send the violation list **verbatim** to the agent that made those changes, using SendMessage to that same agent so it keeps its context. Attempt += 1, then rerun `rules-guardian`.
   - If attempt = 3 (third FAIL): **stop.** Use AskUserQuestion. Show the remaining violations and offer: let the agent try again with a hint from the user / accept as-is / change the rule / drop or redesign the task.

## 4. Playtest
Run `playtester` on the changed files and scenes.
- **OK** → done.
- **ERRORS** → send each error to the responsible agent, then go back to step 3. Playtest failures count toward the same 3-attempt limit.
- Godot executable not found → tell the user to set `GODOT_BIN`, and report the feature as passing QA but not playtested.

## 5. Report to the user
What was built (files), what was reused, number of QA rounds, and anything outstanding.
