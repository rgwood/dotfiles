#!/usr/bin/env bash
set -euo pipefail

SCHEMA=org.gnome.desktop.wm.keybindings
BACKUP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}"
mkdir -p "$BACKUP_DIR"
BACKUP="$BACKUP_DIR/gnome-windowing-backup-$(date +%Y%m%d-%H%M%S).txt"
gsettings list-recursively "$SCHEMA" > "$BACKUP"
echo "Backed up $SCHEMA to $BACKUP"

have() { gsettings list-keys "$SCHEMA" | grep -qx "$1"; }

setkb() {
  local key="$1" val="$2"
  if have "$key"; then
    gsettings set "$SCHEMA" "$key" "$val"
    echo "  set $key = $val"
  else
    echo "  skip $key (not available in this GNOME version)"
  fi
}

setkb move-to-monitor-left     "['<Super><Shift>Left']"
setkb move-to-monitor-right    "['<Super><Shift>Right']"
setkb show-desktop             "['<Primary><Super>d', '<Primary><Alt>d']"
setkb move-to-monitor-up       "['<Super><Shift>Up']"
setkb move-to-monitor-down     "['<Super><Shift>Down']"
setkb switch-to-workspace-up   "['<Super>Page_Up']"
setkb switch-to-workspace-down "['<Super>Page_Down']"
setkb move-to-workspace-up     "['<Super><Shift>Page_Up']"
setkb move-to-workspace-down   "['<Super><Shift>Page_Down']"

TA_UUID=""
for uuid in tiling-assistant@ubuntu.com tiling-assistant@leleat tiling-assistant@leleat-on-github; do
  if gnome-extensions info "$uuid" >/dev/null 2>&1; then TA_UUID="$uuid"; break; fi
done
if [ -n "$TA_UUID" ]; then
  gnome-extensions enable "$TA_UUID" && echo "Enabled Tiling Assistant ($TA_UUID)"
  TA_SCHEMA=org.gnome.shell.extensions.tiling-assistant
  if gsettings list-schemas | grep -qx "$TA_SCHEMA"; then
    gsettings set "$TA_SCHEMA" window-gap 8
    gsettings set "$TA_SCHEMA" screen-top-gap 8
    gsettings set "$TA_SCHEMA" screen-bottom-gap 8
    gsettings set "$TA_SCHEMA" screen-left-gap 8
    gsettings set "$TA_SCHEMA" screen-right-gap 8
    gsettings set "$TA_SCHEMA" maximize-with-gap true
    gsettings set "$TA_SCHEMA" enable-tiling-popup false
    gsettings set "$TA_SCHEMA" dynamic-keybinding-behavior 2
    gsettings set "$TA_SCHEMA" tile-bottom-half "['<Super>Down', '<Super>KP_2']"
    gsettings set "$TA_SCHEMA" restore-window "@as []"
    echo "Configured Tiling Assistant: 8px gaps, dynamic chaining (mode 2), Super+Down on bottom-half"
  fi
else
  echo "Tiling Assistant not installed - see gnome-windowing.md (Extension Manager: search 'Tiling Assistant')"
fi

echo "Done. Verify:  gsettings get $SCHEMA move-to-monitor-left"

echo
echo "==> Installing move-to-next-monitor extension (Super+D cycles monitors)"
NEXT_MON_UUID="move-to-next-monitor@rgwood"
EXT_DIR="${HOME}/.local/share/gnome-shell/extensions/${NEXT_MON_UUID}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="${SCRIPT_DIR}/${NEXT_MON_UUID}"
if [ -d "$SRC_DIR" ]; then
  mkdir -p "$EXT_DIR"
  cp -r "$SRC_DIR"/* "$EXT_DIR/"
  echo "Installed ${NEXT_MON_UUID}"
  # Pre-enable it (GNOME Shell on Wayland needs a relogin to load new extensions)
  CURRENT=$(gsettings get org.gnome.shell enabled-extensions)
  if echo "$CURRENT" | grep -q "$NEXT_MON_UUID"; then
    echo "  already in enabled-extensions"
  else
    NEW=$(echo "$CURRENT" | sed "s/\]/, '${NEXT_MON_UUID}']/")
    gsettings set org.gnome.shell enabled-extensions "$NEW"
    echo "  added to enabled-extensions (log out and back in to activate)"
  fi
else
  echo "  source not found at $SRC_DIR — skipping"
fi

echo
echo "==> keyd: Caps Lock tap=Esc, hold=Super (drives Tiling Assistant via Caps+arrows)"
if command -v keyd >/dev/null 2>&1; then
  echo "keyd already installed, skipping install"
else
  echo "Installing keyd (requires sudo)..."
  sudo add-apt-repository -y ppa:keyd-team/ppa
  sudo apt-get update
  sudo apt-get install -y keyd
fi

KEYD_CONF=/etc/keyd/default.conf
KEYD_WANT='[ids]
*
# Ignore ydotool'"'"'s virtual keyboard (always 2333:6666) so dictation keystrokes
# pass through untouched — see linux/dictation.md. Harmless without ydotool.
-2333:6666
# Ignore the Kinesis foot pedal: handy-ptt.py grabs it for push-to-talk
# dictation (see linux/dictation.md step 8). Harmless without the pedal.
-29ea:0100

[main]
# Tap = Escape, hold = Super/Meta (so Caps+Arrow drives Tiling Assistant)
capslock = overload(meta, esc)
# Remap F1 → F24 and F13 → F24 so handy-ptt.py can do push-to-talk.
# F24 maps to NoSymbol in XKB, so GNOME ignores it (no key-repeat strobe,
# no app help menus, no XF86Tools opening Settings). F13 is also remapped
# because Framework laptops send KEY_F13 for the top-row "F1" key.
# Without handy-ptt running, F1 falls through to the GNOME "Handy Toggle"
# shortcut as tap-to-toggle. See linux/dictation.md step 8.
f1 = f24
f13 = f24
# Remap right Alt → F24 for push-to-talk, directly via keyd.
# compose = f24 is a harmless no-op unless something maps right Alt →
# Compose before keyd sees it.
rightalt = f24
compose = f24
'
if [ -f "$KEYD_CONF" ] && [ "$(sudo cat "$KEYD_CONF")" = "$KEYD_WANT" ]; then
  echo "$KEYD_CONF already up to date"
else
  echo "Writing $KEYD_CONF"
  printf '%s' "$KEYD_WANT" | sudo tee "$KEYD_CONF" >/dev/null
fi

sudo systemctl enable --now keyd
# Restart (not just enable) matters: on first install keyd can come up before
# the config/devices settle and silently ignore all keyboards.
sudo systemctl restart keyd
echo "keyd installed and running. Test: tap Caps = Esc, hold Caps + arrow = tile snap."

echo
echo "==> Binding Super+F to fullscreen (so Caps+F toggles fullscreen)"
gsettings set org.gnome.desktop.wm.keybindings toggle-fullscreen "['<Super>f']"

echo
echo "==> Clearing old xkb caps:escape option (redundant now that keyd handles Caps Lock)"
gsettings set org.gnome.desktop.input-sources xkb-options "[]"
