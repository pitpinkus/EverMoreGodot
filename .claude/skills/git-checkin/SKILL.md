---
name: git-checkin
description: Check in all current work on Evermore — review changes, git add, git commit with a clear message, and git push to the remote. Use when the user says check in, commit, save my work, push, or before switching branches / ending a session.
---

# git-checkin

Runs `git add` → `git commit` → `git push` safely. Work from the project root.

## 1. Look at what changed
```
git status --porcelain
git diff --stat
git diff --cached --stat
```
- Nothing to commit → check whether there are unpushed commits (`git log @{u}..` if an upstream exists). If there are, skip to step 4. Otherwise report "nothing to check in" and stop.

## 2. Guard what gets committed
Before staging, scan the list of changed/untracked files:
- Must **not** be committed: `.godot/`, `.claude/settings.local.json`, `*.tmp`, `Thumbs.db`, `.DS_Store`, `.env`, keys/tokens/passwords, build exports (`/build/`, `/export/`, `*.pck`, `*.exe` outside tools). If any appear, add them to `.gitignore` and mention it in the report.
- Files over ~50 MB: stop and ask the user (suggest Git LFS).
- Godot `*.import` and `*.uid` files **are** committed (Godot needs them).

## 3. Stage and commit
```
git add -A
git status --porcelain     # confirm the staged set is what you expect
```
Write the commit message from the actual diff (`git diff --cached`):
- Subject line: imperative, ≤ 72 chars, says *what* changed (`Add battle turn order system`, `Migrate creature stats from Unity`).
- Body (if more than one thing changed): short bullets of the main changes.
- End with the attribution trailer from the session's current git attribution instructions, if any.

Commit with a here-doc / here-string so the formatting survives:
```
git commit -F - <<'EOF'
<subject>

- <change>
- <change>
EOF
```
If a commit hook fails: read its output, fix the cause if it's trivial, otherwise stop and report. Never use `--no-verify`.

## 4. Push
- `git remote -v` is empty → **stop and ask the user for the remote URL** (e.g. a GitHub repo). After they give it: `git remote add origin <url>`.
- No upstream for the current branch → `git push -u origin <branch>`.
- Otherwise → `git push`.
- Push rejected because the remote is ahead → `git pull --rebase`, then push again. On conflicts: stop, list the conflicted files, and ask the user. Never force-push.
- Auth failure → tell the user to sign in (e.g. `! git push` once in the prompt so the credential manager can open).

## 5. Report
Branch, commit hash + subject, number of files, pushed to `origin/<branch>` (or why not), and any `.gitignore` changes.
