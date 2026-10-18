---
name: ship
description: Finish up the current feature end to end — verify, commit, land it on the default branch, push, deploy if the project deploys, and confirm it works. Use when Reilly says "ship it", "/ship", "finish this up", "wrap this up", or "commit and deploy".
user-invokable: true
args:
  - name: notes
    description: Anything to do differently this time, e.g. "don't deploy" or "skip evals/" (optional)
    required: false
---

Invoking this skill is Reilly's go-ahead to commit, push to the default branch, and deploy in the current repository. Don't ask for confirmation at each step. Do stop and ask if something is ambiguous or risky (see "Stop and ask").

## 1. Survey

- `git status`, current branch, the default branch (`git symbolic-ref refs/remotes/origin/HEAD`, else `main`/`master`), unpushed commits, and whether you're in a worktree.
- Read the diff of everything uncommitted. Know what's being shipped before shipping it.
- Find the project's test, type-check, and deploy commands: `AGENTS.md`/`CLAUDE.md`, README "Deploy"/"Operations" sections, a `deploy.*` script, `justfile`/`Makefile`/`package.json`/`Cargo.toml` targets.

## 2. Verify

Run the tests and type checks the project uses (for PEP 723 scripts: `uvx --with-requirements=<script> ty check <script>`). If they fail, fix the failure if it's clearly caused by this work; otherwise stop and report.

## 3. Commit

- Group changes into logical commits, in separate commits when they're separate ideas. If a file mixes unrelated work, split it by staging intermediate versions (`git hash-object -w` + `git update-index --cacheinfo`) instead of lumping it together, and make sure each intermediate state still passes tests.
- Match the repo's existing commit style (`git log`). Bodies explain why, in Reilly's voice. No attribution lines.
- Before committing, scan staged files for secrets (API keys, passwords, tokens, `.env` files). Placeholders are fine.
- Leave untracked files that look unrelated, generated, or sensitive out, and mention them in the summary.

## 4. Land on the default branch

- On the default branch already: nothing to do.
- On a feature branch: rebase or merge it into the default branch locally (fast-forward when possible), then switch to the default branch. In an app-managed worktree, use the `sync_with_base_branch` tool rather than merging by hand.
- If the repo clearly works through PRs (branch protection, PR-only history, CONTRIBUTING says so), open a PR instead of pushing to the default branch, and say so.

## 5. Push

`git push origin <default-branch>`. Never force-push. If the push is rejected because the remote moved, pull with rebase, re-run the tests, and push again.

## 6. Deploy

- Use the project's deploy script or documented procedure. If there isn't one but the project clearly runs somewhere (systemd unit, README deploy section), follow the documented manual steps, take a backup first, and suggest adding a deploy script.
- If the project doesn't deploy (a library, a CLI used locally), skip this and say so.
- Then confirm it actually works: health check, service status, recent logs free of new errors, and if cheap, one real exercise of the changed code path.

## 7. Report

A short summary: the commits (hash + subject), where they landed, that they're pushed, what was deployed and how you checked it, and anything left over (skipped files, follow-ups).

## Stop and ask

- Tests fail for reasons unrelated to this work.
- Uncommitted changes include work you don't recognise and can't tell is meant to ship.
- Landing would need a force-push, or a merge has non-trivial conflicts.
- A deploy failed and rolled back, or the post-deploy check looks wrong.
- Shipping would touch something outside this repo beyond its documented deploy target.
