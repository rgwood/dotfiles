#!/usr/bin/env python3
# Plain python3 shebang (not uv) on purpose: stdlib-only, and it runs as a
# systemd user service where I want zero moving parts at boot.
"""Push-to-talk for Handy dictation via foot pedal, F1 key, and/or right Alt.

Wayland/GNOME can't do push-to-talk: GNOME shortcuts can't tell key press
from release and re-fire on key-repeat. But dedicated input devices can:
we read their raw kernel events from /dev/input (where press/release/repeat
ARE distinct).

Three triggers, same daemon:

1. **Foot pedal** (Kinesis Savant Elite2): grabbed exclusively
   (EVIOCGRAB) so its F1 never reaches GNOME. Press → SIGUSR2 (start),
   release → SIGUSR2 (stop + transcribe). If the daemon dies the grab
   releases and the pedal's F1 falls through to the GNOME "Handy Toggle"
   shortcut (tap-to-toggle).

2. **Keyboard F1 / right Alt** (via keyd): keyd remaps F1 → F24, F13 →
   F24, and Compose → F24 on its virtual keyboard. F13 covers Framework
   laptops whose top-row "F1" sends KEY_F13 at the hardware level;
   Compose covers right Alt (input-remapper maps right Alt → Compose).
   F24 maps to NoSymbol in XKB, so GNOME ignores it entirely — no
   strobing shortcut, no app help menus, no XF86Tools opening Settings.
   The daemon reads F24 from keyd's virtual keyboard *without grabbing*
   (grabbing would starve GNOME of all keyboard input). Press → SIGUSR2
   (start), release → SIGUSR2 (stop + transcribe). If keyd isn't running,
   these keys are unaffected — they fall through to the GNOME shortcut as
   before.

Handy stays in *toggle* mode; press+release = start+stop = push-to-talk.
All triggers send SIGUSR2 to the same Handy process, so simultaneous use
can desync toggle state (same limitation as pedal + keyboard F1 toggle).

Needs the `input` group and keyd must NOT grab the pedal (exclude
29ea:0100 in /etc/keyd/default.conf). The keyd virtual keyboard needs a
udev uaccess rule for the daemon to read it — see dictation.md step 8.
"""

import os
import select
import struct
import subprocess
import time
from fcntl import ioctl

PEDAL_NAME_PREFIX = "Kinesis Savant Elite2 Foot Pedal"
KEYD_VKBD_NAME = "keyd virtual keyboard"
KEY_F24 = 194  # /usr/include/linux/input-event-codes.h; keyd remaps F1 → F24
# struct input_event on 64-bit: time (sec, usec), type, code, value
EVENT_FMT = "llHHi"
EVENT_SIZE = struct.calcsize(EVENT_FMT)
EV_KEY = 0x01
EVIOCGRAB = 0x40044590


def log(msg: str) -> None:
    print(msg, flush=True)  # stdout -> journald via the user service


def find_pedal_nodes() -> list[str]:
    """Every /dev/input/event* node belonging to the pedal.

    The Savant Elite2 exposes four nodes (keyboard, mouse, consumer control,
    system control). We grab them all so nothing it sends leaks to GNOME,
    whatever the pedals are programmed as.
    """
    nodes: list[str] = []
    name = ""
    with open("/proc/bus/input/devices") as f:
        for line in f:
            if line.startswith("N: Name="):
                name = line.split("=", 1)[1].strip().strip('"')
            elif line.startswith("H: Handlers=") and name.startswith(PEDAL_NAME_PREFIX):
                handlers = line.split("=", 1)[1].split()
                nodes += [f"/dev/input/{h}" for h in handlers if h.startswith("event")]
    return nodes


def find_keyd_vkbd_node() -> str | None:
    """The /dev/input/event* node for keyd's virtual keyboard, or None.

    keyd remaps F1→F24 here; we read F24 for push-to-talk without grabbing
    (grabbing would starve GNOME of all keyboard input). Returns None if
    keyd isn't running.
    """
    name = ""
    with open("/proc/bus/input/devices") as f:
        for line in f:
            if line.startswith("N: Name="):
                name = line.split("=", 1)[1].strip().strip('"')
            elif line.startswith("H: Handlers=") and name == KEYD_VKBD_NAME:
                for h in line.split("=", 1)[1].split():
                    if h.startswith("event"):
                        return f"/dev/input/{h}"
    return None


def open_and_grab(nodes: list[str]) -> dict[int, str]:
    fds: dict[int, str] = {}
    for path in nodes:
        try:
            fd = os.open(path, os.O_RDONLY)
        except OSError as e:
            log(f"warning: open {path}: {e}")
            continue
        try:
            ioctl(fd, EVIOCGRAB, 1)
        except OSError as e:
            # EBUSY here usually means keyd still grabs the pedal — check
            # /etc/keyd/default.conf for the -29ea:0100 exclusion.
            log(f"warning: grab {path}: {e}")
            os.close(fd)
            continue
        fds[fd] = path
    return fds


def open_readonly(path: str) -> int | None:
    """Open an input device for passive monitoring (no exclusive grab)."""
    try:
        return os.open(path, os.O_RDONLY)
    except OSError as e:
        log(f"warning: open {path}: {e}")
        return None


def toggle_handy() -> None:
    subprocess.run(["pkill", "-USR2", "handy"])


def pump_events(pedal_fds: dict[int, str], keyd_fd: int | None) -> None:
    """Translate pedal and/or F1 press/release into Handy toggles.

    Returns on device loss (unplug, keyd restart).
    """
    pedal_held = 0  # pedals currently down (there are three; signal on first/last)
    f1_held = False
    all_fds = list(pedal_fds)
    if keyd_fd is not None:
        all_fds.append(keyd_fd)
    while True:
        readable, _, _ = select.select(all_fds, [], [])
        for fd in readable:
            try:
                data = os.read(fd, EVENT_SIZE * 64)
            except OSError:
                return  # unplugged; rescan
            is_keyd = fd == keyd_fd
            for off in range(0, len(data), EVENT_SIZE):
                _, _, etype, code, value = struct.unpack_from(EVENT_FMT, data, off)
                if etype != EV_KEY or value == 2:  # value 2 = key-repeat, ignore
                    continue
                if is_keyd:
                    if code != KEY_F24:
                        continue  # only F24 (=remapped F1) triggers PTT
                    if value == 1 and not f1_held:
                        f1_held = True
                        toggle_handy()
                        log("F1 down -> start recording")
                    elif value == 0 and f1_held:
                        f1_held = False
                        toggle_handy()
                        log("F1 up -> stop + transcribe")
                else:
                    if value == 1:
                        pedal_held += 1
                        if pedal_held == 1:
                            toggle_handy()
                            log(f"pedal down (code {code}) -> start recording")
                    else:
                        pedal_held = max(0, pedal_held - 1)
                        if pedal_held == 0:
                            toggle_handy()
                            log(f"pedal up (code {code}) -> stop + transcribe")


def main() -> None:
    log("handy-ptt starting")
    while True:
        pedal_nodes = find_pedal_nodes()
        keyd_node = find_keyd_vkbd_node()

        pedal_fds = open_and_grab(pedal_nodes) if pedal_nodes else {}
        keyd_fd = open_readonly(keyd_node) if keyd_node else None

        if not pedal_fds and keyd_fd is None:
            time.sleep(3)
            continue

        parts = []
        if pedal_fds:
            parts.append(f"grabbed {', '.join(pedal_fds.values())}")
        if keyd_fd is not None:
            parts.append(f"watching {keyd_node} for F1 push-to-talk")
        log("; ".join(parts))

        pump_events(pedal_fds, keyd_fd)

        for fd in pedal_fds:
            os.close(fd)
        if keyd_fd is not None:
            os.close(keyd_fd)
        log("device disappeared; rescanning")
        time.sleep(1)


if __name__ == "__main__":
    main()
