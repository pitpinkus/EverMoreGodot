---
name: git-checkout
description: Switch Evermore to another git branch. Takes the target branch name as its argument (e.g. /git-checkout feature/battle-system). Refuses while there are uncommitted changes and asks the user to run /git-checkin first.
argument-hint: <target-branch>
---

# git-checkout

Target branch: **$ARGUMENTS**

## 1. Argument
If no branch name was given, ask the user which branch, and list the options:
`git branch --all --format="%(refname:short)"`.

## 2. Rule G1: clean tree required
```
git status --porcelain
```
If there is **any** output: **stop.** Don't stash, don't discard, don't check out. Tell the user:
> You have N uncommitted change(s). Please run `/git-checkin` first, then `/git-checkout <branch>` again.

Show the list of changed files.

## 3. Find the branch
1. If a remote exists: `git fetch --prune origin`.
2. Already on that branch (`git branch --show-current`) → report and stop.
3. Local branch exists (`git show-ref --verify --quiet refs/heads/<branch>`) → `git switch <branch>`, then `git pull --ff-only` if it has an upstream.
4. Only on the remote (`refs/remotes/origin/<branch>`) → `git switch --track origin/<branch>`.
5. Doesn't exist anywhere → ask the user: create `<branch>` from the current branch? If yes: `git switch -c <branch>`. If a remote exists, offer to publish it with `git push -u origin <branch>`.

If `pull --ff-only` fails because the branches have diverged: stop and ask the user (merge, rebase or leave as is).

## 4. Report
Previous branch → new branch, latest commit (`git log -1 --oneline`), and whether it's up to date with `origin`.
