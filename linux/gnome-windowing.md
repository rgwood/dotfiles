# Windowing keyboard shortcuts (GNOME)

Turns vanilla GNOME/Ubuntu into a keyboard-driven windowing environment
*without* switching to a tiling WM. Run by hand (like `macos/defaults.sh`),
not by `./install`.

Design goals:

1. **Build on what you know** — Super+Left/Right keep working.
2. **Noob-friendly** — no config-file rabbit holes; one script + one extension.
3. **Mac parity baked in** — every binding maps to your existing BetterTouchTool
   setup (`macos/Reilly.bttpreset`), so both OSes stay in sync.
4. **Gradual** — if you outgrow this, the scheme is a subset of i3/Sway/Hyprland,
   so muscle memory transfers.

---

## The keybinding scheme

| Action                       | Shortcut                  | Where it comes from        |
|------------------------------|---------------------------|----------------------------|
| Snap to left / right half    | `Super+←` / `Super+→`     | Tiling Assistant           |
| Snap to top / bottom half    | `Super+↑` / `Super+↓`     | Tiling Assistant (chaining)|
| Snap to a quarter (corner)   | chain two arrow presses   | Tiling Assistant           |
| Maximize / restore           | `Super+↑` from floating / `Super+↓` from maximized | Tiling Assistant |
| Untile (back to floating)    | same direction again, or opposite direction | Tiling Assistant |
| Switch workspace             | `Super+PgUp` / `Super+PgDn` | GNOME default / script |
| Move window to workspace     | `Super+Shift+PgUp` / `Super+Shift+PgDn` | GNOME default / script |
| Move window to monitor       | `Super+Shift+←/→/↑/↓`     | script (added)             |
| Cycle windows                | `Alt+Tab`                 | GNOME default              |
| Activities / app launcher    | `Super`                   | GNOME default              |
| Fullscreen                   | `Super+F` (i.e. `Caps+F`) | script (added) + keyd      |

`Caps+arrows` works the same as `Super+arrows` above because of the keyd setup
below — holding Caps Lock sends Super/Meta. So the whole table works from
either key.

### How arrow chaining works

Tiling Assistant runs in **dynamic mode** (`dynamic-keybinding-behavior=2`,
set by the script). The mental model:

> **Super+arrows tile toward that direction. If you're already on that side,
> it shrinks toward that corner. Press the same direction again — or the
> opposite direction — to untile back to floating.**

A tour that hits all four quarters (try it on any window):

1. `Super+←` → left half
2. `Super+↑` → top-left quarter
3. `Super+↓` → left half (expands back down)
4. `Super+↓` → bottom-left quarter
5. `Super+→` → bottom half (expands across)
6. `Super+→` → bottom-right quarter
7. `Super+↑` → right half (expands up)
8. `Super+→` → untile (floating)

Untile cheatsheet: from a **half**, press the same or opposite direction; from
**maximized**, press `Super+↓`; from a **quarter**, any arrow first expands to a
half (then untile from there).

> Note: the script deliberately **unbinds** TA's `restore-window` and puts
> `Super+Down` on `tile-bottom-half` instead. Without this, `Super+Down` is
> captured by "restore to floating" and you can never chain downward — the
> single most common confusion with TA's defaults.

---

## Apply it

```sh
~/dotfiles/linux/gnome-windowing.sh
```

The script only **adds** bindings GNOME doesn't ship by default (monitor moves)
and makes the workspace-up/down bindings deterministic across Ubuntu versions.
It backs up your current `org.gnome.desktop.wm.keybindings` to
`~/.local/share/gnome-windowing-backup-*.txt` first, and skips any key that
doesn't exist on your GNOME version (so it won't error on older/newer releases).

Verify after running:

```sh
gsettings get org.gnome.desktop.wm.keybindings move-to-monitor-left
# expect: ['<Super><Shift>Left']
```

---

## Install the Tiling Assistant extension

**Ubuntu 24.04+ already ships it** as a system extension (`tiling-assistant@ubuntu.com`,
a repackaging of upstream `tiling-assistant@leleat`). Check with:

```sh
gnome-extensions info tiling-assistant@ubuntu.com
```

If `State: ACTIVE`, you're done — the script enables it and configures gaps
automatically. Skip to [Tuning](#tuning-tiling-assistant) below.

If it's *not* installed (other distros, or you want upstream), use Extension
Manager:

1. Install it:
   ```sh
   flatpak install flathub com.mattjakeman.ExtensionManager
   ```
   (or `apt install gnome-shell-extension-manager` on Ubuntu.)
2. Open it → search **"Tiling Assistant"** → Install → toggle On.
3. Re-run the script to enable + configure it.

### Tuning Tiling Assistant

The script sets these defaults (all reversible via Extension Manager's GUI or
`gsettings`):

| Setting                       | Value  | Effect                                   |
|-------------------------------|--------|------------------------------------------|
| `window-gap`                  | 8      | 8px gap between tiled windows            |
| `screen-*-gap` (×4)           | 8      | 8px margin around screen edges           |
| `maximize-with-gap`           | true   | maximized windows keep the screen margin |
| `enable-tiling-popup`         | false  | Snap Assist popup disabled (it steals focus from arrow chaining) |
| `dynamic-keybinding-behavior` | 2      | "Tiling state" mode — arrows chain halves↔quarters↔untile |
| `tile-bottom-half`            | `Super+↓` | makes Down participate in chaining (default is numpad-only) |
| `restore-window`              | unbound | frees `Super+↓` for chaining; untile via same/opposite direction |

Other handy keys to explore (GUI: Extension Manager → Tiling Assistant → gear):

- `dynamic-keybinding-behavior` `3` (TILING_STATE_WINDOWS) — same as `2` but
  `Super+↓` *minimizes* when pressed at the bottom state (Windows-11 style).
  Try it if you want minimize-on-bottom.
- `tilegroups-in-app-switcher` — group tiled windows together in Alt+Tab.
- `favorite-layouts` / `activate-layout0..19` — save and trigger named layouts
  with a shortcut (advanced; closest thing to a tiling WM's named workspaces).

---

## Caps Lock as Super (keyd): tap = Esc, hold = Super

The whole point of this scheme is Super+arrows for tiling, but reaching for
the actual `Super` key while typing is awkward. The fix: remap Caps Lock so a
**tap** sends `Esc` (the classic vim remap) and a **hold** sends `Super`. Then
`Caps+arrows` drives Tiling Assistant and `Caps+F` toggles fullscreen, all
without moving your hand off home row.

This needs [`keyd`](https://github.com/rvaiya/keyd), a system-level key
remapper (works underneath GNOME/X11/Wayland, unlike GNOME's own xkb options
which can't do tap-vs-hold). The `gnome-windowing.sh` script above installs
and configures it; here's what it does, spelled out:

```sh
sudo add-apt-repository -y ppa:keyd-team/ppa
sudo apt-get install -y keyd
```

Then it writes `/etc/keyd/default.conf`:

```
[ids]
*

[main]
# Tap = Escape, hold = Super/Meta (so Caps+Arrow drives Tiling Assistant)
capslock = overload(meta, esc)
```

And enables/starts the service:

```sh
sudo systemctl enable --now keyd
sudo systemctl restart keyd
```

> **Why `restart` and not just `enable --now`?** On a fresh install, keyd can
> come up before its config or the input devices have settled, and it'll
> silently ignore every keyboard — no error, it just doesn't work. Restarting
> once everything's actually up fixes it. If Caps Lock isn't doing anything
> after a fresh install, this is the first thing to try:
> `sudo systemctl restart keyd`.

Then bind fullscreen to Super+F, so Caps+F reaches it too:

```sh
gsettings set org.gnome.desktop.wm.keybindings toggle-fullscreen "['<Super>f']"
```

Finally, clear the old GNOME xkb `caps:escape` option if you'd set it before —
it's redundant (and can conflict) once keyd owns Caps Lock:

```sh
gsettings set org.gnome.desktop.input-sources xkb-options "[]"
```

### If Caps Lock ever gets stuck / stops working

keyd has a **panic sequence** built in: press `Backspace+Escape+Enter`
together and it kills the daemon immediately, releasing all keys back to
normal. Useful if a bad config locks up your keyboard. After that, fix
`/etc/keyd/default.conf` and `sudo systemctl restart keyd`.

### Coexisting with input-remapper

This machine also runs [`input-remapper`](https://github.com/sezanzeb/input-remapper)
for other device remaps. The two don't fight: input-remapper grabs the
physical keyboard devices and creates new virtual "forwarded" devices; keyd
then attaches to those forwarded devices rather than the physical ones. Both
run fine side by side — no special config needed, just install both and it
works.

### Test it

```sh
# tap Caps -> should act as Esc
# hold Caps + Left -> window should snap left (same as Super+Left)
# hold Caps + F -> fullscreen toggle
```

---

## Optional: numbered workspaces (Super+1..9)

GNOME doesn't bind `Super+1..9` to workspaces by default, and Ubuntu's dock
*does* use `Super+1..9` to launch pinned apps — so this is optional and trades
dock-launch shortcuts for i3-style workspace jumping. Only do this if you don't
use the dock's number shortcuts.

```sh
gsettings set org.gnome.shell.extensions.dash-to-dock hot-keys false

for i in 1 2 3 4 5 6 7 8 9; do
  gsettings set org.gnome.desktop.wm.keybindings "switch-to-workspace-$i" "['<Super>$i']"
  gsettings set org.gnome.desktop.wm.keybindings "move-to-workspace-$i"    "['<Super><Shift>$i']"
done
```

> On **dash-to-panel** (instead of the dock): the gsettings line above may not
> cover it. Open *Dash to Panel Settings → Behavior → Hotkeys for window
> activation* and turn that off too, or the panel will still grab `Super+1..9`.

---

## Mac parity (BetterTouchTool)

You already use BetterTouchTool — `macos/Reilly.bttpreset` has snap areas
enabled (`cornerSnap`, `snapTopLeft`, `snapBottomRight`, half-edge snapping).
That covers *drag-to-edge* snapping. For **keyboard parity** with the Linux
scheme above, add these as keyboard-shortcut triggers in BTT
(Configuration → add trigger → Keyboard Shortcut → assign the Window action):

| Linux                    | Mac shortcut (suggested) | BTT action                          |
|--------------------------|--------------------------|-------------------------------------|
| `Super+←/→` half         | `⌃⌥←` / `⌃⌥→`            | Window: Move to Left/Right Half     |
| `Super+↑` maximize       | `⌃⌥↑`                    | Window: Maximize                    |
| `Super+↓` restore        | `⌃⌥↓`                    | Window: Restore (Undo last move)    |
| `Super+↑/↓` top/bottom half | `⌃⌘↑` / `⌃⌘↓`         | Window: Move to Top/Bottom Half     |
| Quarter (via chaining)   | `⌃⌥` + drag, or set `⌃⌥⌘↑/↓←/→` to the four quarter actions | Window: Move to Top-Left/Top-Right/Bottom-Left/Bottom-Right Quarter |
| `Super+Shift+←/→` monitor | `⌃⌥⌘←` / `⌃⌥⌘→`        | Window: Move to Next/Previous Monitor |
| `Super+PgUp/PgDn` workspace | `⌃←` / `⌃→`           | (macOS Spaces default — no BTT needed) |
| `Super+Shift+PgUp/PgDn` move-to-workspace | `⌃⌘←` / `⌃⌘→` | Move window to Next/Previous Space (BTT action) |

Notes:

- `⌃⌥` (Ctrl+Option) matches Rectangle's defaults, so if you ever run Rectangle
  alongside BTT the keys stay familiar. Pick whatever modifier you prefer —
  just keep it consistent across the table.
- BTT can't fully replicate GNOME's *arrow chaining* (quarter via two presses);
  instead bind four distinct quarter shortcuts (`⌃⌥⌘↑/↓/←/→` or similar). The
  drag-to-edge snap areas you already have are the ergonomic alternative.
- Export updated presets back to `macos/Reilly.bttpreset` so this stays in git.

### Alternatives (if you ever move off BTT)

- **Rectangle** — free, just the snap shortcuts, 5-minute setup.
- **Hammerspoon** — free, Lua-scripted; closest to a config-file parity with
  this repo.
- **Aerospace** — free, full i3-style tiling on macOS; pick this if you
  graduate to real tiling on *both* OSes.

---

## Graduation path (if you outgrow GNOME)

If you find yourself wanting auto-tiling, keyboard-driven layout, and a text
config, the natural next step on Linux is **Sway** (Wayland, i3-compatible) or
**Hyprland** (Wayland, animated). The scheme above is a strict subset of their
defaults, so nothing is wasted. On macOS the matching move is **Aerospace** or
**yabai** (yabai needs SIP partially disabled for full features).

---

## Troubleshooting

- **A binding didn't apply** → check it exists and its current value:
  ```sh
  gsettings list-recursively org.gnome.desktop.wm.keybindings | grep -i monitor
  ```
- **Super+Left/Right stopped snapping** → ensure Tiling Assistant is on and the
  GNOME defaults are intact: `gsettings get org.gnome.desktop.wm.keybindings toggle-tiled-left`
  should be `['<Super>left']`.
- **Super+Down untiles instead of chaining to a quarter** → the script's
  `restore-window=@as []` + `tile-bottom-half=['<Super>Down']` fix didn't apply.
  Re-run the script, or set them manually (see the Tuning table).
- **Restore your old bindings** → each run writes a backup to
  `~/.local/share/gnome-windowing-backup-*.txt`; inspect it and `gsettings set`
  back any value.
- **Which GNOME version am I on?** → `gnome-shell --version` (Tiling Assistant
  needs GNOME 40+; Ubuntu 22.04+ is fine).
- **Caps Lock does nothing after install** → `sudo systemctl restart keyd`
  (see the keyd section above — this is a known first-boot race).
- **Keyboard is completely unresponsive** → panic sequence:
  `Backspace+Escape+Enter` kills keyd and restores normal input.
- **Caps+arrows don't work but Super+arrows do** → check keyd is running
  (`systemctl status keyd`) and, if you also run input-remapper, that it's
  forwarding devices correctly (`sudo keyd monitor` while pressing Caps should
  show key events).
