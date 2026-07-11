# Voice dictation on Linux (GNOME Wayland)

Local speech-to-text à la MacWhisper: press a key, talk, text appears in
whatever app has focus. This uses [Handy](https://github.com/cjpais/Handy)
(open source, offline, Parakeet/Whisper models).

Sounds simple. It was not. On GNOME **Wayland**, five independent things had
to be fixed before the first word landed in a text box — each one failing
*silently* while claiming success. This doc exists so nobody (me included)
ever debugs this chain blind again.

## Why it's hard on Wayland

Wayland deliberately blocks the two things a dictation app needs:

1. **Global hotkeys** — apps can't grab system-wide keys (that's the
   compositor's job). Handy's built-in hotkey listener just never fires.
2. **Synthetic keyboard input** — apps can't fake keystrokes into other apps.
   So even after transcribing, Handy can't type the result.

Both need workarounds. On X11 none of this applies — if you're on Xorg, just
install Handy and you're done.

## Setup

### 1. Install Handy

Grab the `.deb` from [Handy releases](https://github.com/cjpais/Handy/releases):

```sh
sudo apt install ./Handy_*_amd64.deb
sudo apt install -y libopenblas0
```

> `libopenblas0` is an undeclared runtime dep — without it Handy **crashes
> silently on launch** (no window, no error). `handy` from a terminal shows
> the missing-library error.

### 2. ydotool — build from source, don't use the Ubuntu package

Handy types the transcript via [ydotool](https://github.com/ReimuNotMoe/ydotool),
which injects input at the kernel level (`/dev/uinput`), below Wayland's
restrictions. Two traps:

- **Ubuntu 24.04's `ydotool` 0.1.8 package is broken**: it exits 0 while
  injecting *nothing*. Handy logs "Text pasted successfully" and no text
  appears anywhere. Build 1.0.4+ from source.
- `wtype` is not an option on GNOME (GNOME doesn't implement
  `virtual-keyboard-unstable-v1`).

```sh
sudo apt install -y cmake scdoc libevdev-dev
git clone --depth 1 --branch v1.0.4 https://github.com/ReimuNotMoe/ydotool.git
cd ydotool && mkdir build && cd build
cmake .. && make -j$(nproc)
sudo make install   # installs to /usr/local/bin, shadowing any apt version
```

Permissions for `/dev/uinput` (then **log out and back in**):

```sh
sudo usermod -aG input $USER
echo 'KERNEL=="uinput", GROUP="input", MODE="0660"' | sudo tee /etc/udev/rules.d/60-ydotool.rules
sudo udevadm control --reload-rules && sudo udevadm trigger
```

### 3. ydotoold user service

`~/.config/systemd/user/ydotoold.service`:

```ini
[Unit]
Description=ydotool daemon

[Service]
# %t = /run/user/UID — this is where the ydotool 1.0.x CLIENT looks by
# default. Older guides say /tmp/.ydotool_socket; that's the 0.1.8 path.
# Mismatch = client can't find daemon = "ydotool failed" in Handy's log.
ExecStart=/usr/local/bin/ydotoold --socket-path=%t/.ydotool_socket --socket-own=%U:%G
Restart=always

[Install]
WantedBy=default.target
```

```sh
systemctl --user daemon-reload
systemctl --user enable --now ydotoold
ydotool type "it works"   # should type into the focused window, exit 0
```

### 4. keyd must ignore ydotool's virtual device

If you run [keyd](https://github.com/rvaiya/keyd) (see
[gnome-windowing.md](gnome-windowing.md)), its default `[ids] *` grabs
**every** keyboard — including ydotool's virtual one — and can eat the
injected keystrokes. Exclude ydotool's device ID (it's always `2333:6666`)
in `/etc/keyd/default.conf`:

```
[ids]
*
-2333:6666
```

Then `sudo systemctl restart keyd`. `gnome-windowing.sh` writes this
exclusion by default now. Harmless on machines without ydotool.

### 5. Trigger: GNOME shortcut → Unix signal

Handy's own hotkey can't work on Wayland, but it listens for `SIGUSR2` as a
toggle. Let GNOME own the hotkey (the compositor is *allowed* to):

```sh
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings \
  "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']"
KB=org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/
gsettings set $KB name 'Handy Toggle'
gsettings set $KB command 'pkill -USR2 handy'
gsettings set $KB binding 'F1'
```

**Use toggle mode in Handy, not push-to-talk.** GNOME shortcuts fire on
key-repeat while held, so PTT becomes a rapid on/off strobe. Tap to start,
tap to stop.

### 6. Handy settings — turn the overlay OFF

In Handy's settings: set the recording **overlay to None**, paste method
**Direct**, typing tool **ydotool**, and switch the transcribe binding mode
to **toggle**.

The overlay one is critical and was the final boss of the original debugging
session: Handy's live-transcription overlay (gtk-layer-shell) **steals
keyboard focus on Wayland**. Everything works — ydotool injects perfect
keystrokes, mutter reads them — but they're delivered to the overlay instead
of your editor, and the overlay vanishes before you can tell. Handy logs
"Text pasted successfully" the whole time.

Settings live in `~/.local/share/com.pais.handy/settings_store.json`; logs in
`~/.local/share/com.pais.handy/logs/handy.log` (set log level to debug in the
app for the useful lines).

### 7. Optional: the shim — 10× faster typing + working auto-submit

Two more Handy shortcomings, one fix. First: Direct paste types
character-by-character with slow defaults (`--key-hold 20` + `--key-delay 20`
= ~40ms/char; a 100-char sentence takes 4 seconds), and Handy invokes plain
`ydotool type -- <text>` with no way to pass flags. Second: Handy's
auto-submit ("press Enter after transcription") is **structurally broken on
Wayland** — `send_return_key` in v0.9.0's `clipboard.rs` hardcodes enigo,
which falls back to X11/XTEST, and native Wayland apps never see the Enter.
(The text-typing path checks Wayland and uses ydotool; the Enter path just…
doesn't.)

Both fixed by a shim: Handy resolves `ydotool` via `PATH`, and `~/.cargo/bin`
comes first:

```sh
cat > ~/.cargo/bin/ydotool << 'EOF'
#!/bin/sh
# Shim for Handy dictation (see dotfiles/linux/dictation.md). Front-runs
# /usr/local/bin/ydotool in PATH. Two jobs:
#  1. Faster typing: Handy invokes bare `ydotool type` (40ms/char defaults).
#  2. Auto-submit: Handy's own auto-submit sends Enter via enigo/XTEST, which
#     native Wayland apps never receive. So when Handy is the caller, follow
#     the transcript with an Enter (keycode 28) through ydotool instead.
#     Delete the marked lines to stop pressing Enter after dictation.
if [ "$1" = "type" ]; then
    shift
    /usr/local/bin/ydotool type --key-delay 2 --key-hold 2 "$@" || exit $?
    if [ "$(cat /proc/$PPID/comm 2>/dev/null)" = "handy" ]; then   # auto-submit
        exec /usr/local/bin/ydotool key 28:1 28:0                  # auto-submit
    fi
    exit 0
fi
exec /usr/local/bin/ydotool "$@"
EOF
chmod +x ~/.cargo/bin/ydotool
```

Notes:

- Typing speed measured at 44 chars in 182ms (~4ms/char). If an app ever
  drops characters, raise the numbers — 5/5 is still 4× faster than stock.
- The parent-process check means manual `ydotool` use is untouched; only
  Handy's dictation gets the trailing Enter.
- **Keep auto-submit OFF in Handy's settings** — the shim replaces it. If
  it's on, XWayland apps would get a *second* Enter via the XTEST path.
- If dictation ever behaves strangely, remember this shim exists
  (`which ydotool` should remind you).

## Troubleshooting

Every row below is a failure mode I actually hit, in order:

| Symptom | Cause | Fix |
|---|---|---|
| Handy launches, no window, no error | missing `libopenblas0` | `sudo apt install libopenblas0`; run `handy` in a terminal to see loader errors |
| Hotkey does nothing | Wayland blocks app global hotkeys | GNOME shortcut → `pkill -USR2 handy` (step 5) |
| Recording icon strobes on/off while key held | GNOME shortcut fires on key-repeat | toggle mode, not push-to-talk |
| Log says "pasted successfully", no text, ydotool is 0.1.x | Ubuntu's ydotool package is broken | build 1.0.4+ from source (step 2) |
| "Failed to Paste Text" / log "ydotool failed" | client/daemon socket path mismatch | daemon must listen on `/run/user/UID/.ydotool_socket` (step 3) |
| ydotool works manually but dictation types nothing, log says success | **overlay stealing focus** | disable the overlay (step 6) |
| Everything worked, then broke after re-running gnome-windowing.sh | keyd config rewritten without the exclusion | re-add `-2333:6666` (step 4) |

## Debugging notes (mostly for future agents)

- **Trust nothing that exits 0.** Three different layers here reported
  success while doing nothing (ydotool 0.1.8, Handy's paste, my own tests).
- To verify injection for real, read the `ydotoold virtual device` node under
  `/dev/input/` while running `ydotool type hi` and check for `EV_KEY`
  events. Find the node via `grep -A5 ydotoold /proc/bus/input/devices`.
- Reading `/dev/input/*` needs the `input` group **active in your process**.
  A shell started before the group was added silently lacks it (`id` shows
  the truth; `groups $USER` shows what you'd get after relogin). `sg input -c
  '...'` gets you the group without relogging. I burned an hour on false
  "no events" results because a `try/except` was eating `EACCES`.
- Is the compositor even listening? `gnome-shell` runs as your user:
  `ls -l /proc/$(pgrep -x gnome-shell)/fd | grep input/event` shows which
  devices mutter has open.
- `strace -e trace=connect ydotool type x` shows which socket path the client
  actually tries.

## If this all sounds terrible

It kind of is. The escape hatches, in increasing order of drasticness:

- Log into **"Ubuntu on Xorg"** at the GDM gear icon — Handy's hotkeys and
  typing then work out of the box, none of the above needed.
- Wait for [Handy's Wayland META issue](https://github.com/cjpais/Handy/issues/1555)
  to land portal-based shortcuts and input.
- Buy a Mac and use MacWhisper like the person who wrote this originally
  wanted to.
