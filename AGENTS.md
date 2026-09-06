# Dotfiles

Reilly's dotfiles, managed with [dotbot](https://github.com/anishathalye/dotbot).

## Install

```
./install
```

Idempotent — safe to re-run. Links configs, creates directories, and runs
`scripts/ensure-tools.py` to install missing CLI tools.

## Platforms

- **macOS** — work machine
- **Linux** — home machine
- **Windows** — frozen, unmaintained. All Windows/WSL material is quarantined
  under `windows/` and not linked by `./install`. Internal paths are stale.

## Shells

- **nushell** — daily driver (`nu/config.nu`, `nu/env.nu`)
- **zsh** — login/fallback (`zsh/zshrc`)
- **starship** — zsh prompt (`starship.toml`)

## Mirrored block

PATH entries, EDITOR/VISUAL, and `mkd` are duplicated across
shells inside `# ─── BEGIN/END mirrored block ───` markers. The markers live
in `zsh/zshrc`, `nu/env.nu`, and `nu/config.nu`. **Keep them in sync manually
— no codegen.** When changing PATH or a shared alias, update all three files.

`lg` is shared through `bin/lg` rather than separate shell aliases.
