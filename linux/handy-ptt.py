#!/usr/bin/env python3
# Plain python3 shebang (not uv) on purpose: stdlib-only, and it runs as a
# systemd user service where I want zero moving parts at boot.
"""Push-to-talk for Handy dictation via the Kinesis Savant Elite2 foot pedal.

Wayland/GNOME can't do push-to-talk: GNOME shortcuts can't tell key press
from release and re-fire on key-repeat. But the pedal is its own USB device,
so we read its raw kernel events from /dev/input (where press/release/repeat
ARE distinct), grab the device exclusively so its F1 never reaches GNOME,
and toggle Handy (SIGUSR2) once on press and once on release. Handy stays in
*toggle* mode; press+release = start+stop = push-to-talk.

If this daemon isn't running, the grab is released and the pedal's F1 falls
through to the GNOME "Handy Toggle" shortcut — i.e. the pedal degrades to
tap-to-toggle rather than going dead.

Needs the `input` group and keyd must NOT grab the pedal (exclude 29ea:0100
in /etc/keyd/default.conf). See dotfiles/linux/dictation.md, step 8.
"""

import os
import select
import struct
import subprocess
import time
from fcntl import ioctl

DEVICE_NAME_PREFIX = "Kinesis Savant Elite2 Foot Pedal"
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
            elif line.startswith("H: Handlers=") and name.startswith(DEVICE_NAME_PREFIX):
                handlers = line.split("=", 1)[1].split()
                nodes += [f"/dev/input/{h}" for h in handlers if h.startswith("event")]
    return nodes


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


def toggle_handy() -> None:
    subprocess.run(["pkill", "-USR2", "handy"])


def pump_events(fds: dict[int, str]) -> None:
    """Translate pedal press/release into Handy toggles. Returns on device loss."""
    held = 0  # pedals currently down (there are three; only signal on first/last)
    while True:
        readable, _, _ = select.select(list(fds), [], [])
        for fd in readable:
            try:
                data = os.read(fd, EVENT_SIZE * 64)
            except OSError:
                return  # unplugged; rescan
            for off in range(0, len(data), EVENT_SIZE):
                _, _, etype, code, value = struct.unpack_from(EVENT_FMT, data, off)
                if etype != EV_KEY or value == 2:  # value 2 = key-repeat, ignore
                    continue
                if value == 1:
                    held += 1
                    if held == 1:
                        toggle_handy()
                        log(f"pedal down (code {code}) -> start recording")
                else:
                    held = max(0, held - 1)
                    if held == 0:
                        toggle_handy()
                        log(f"pedal up (code {code}) -> stop + transcribe")


def main() -> None:
    log("handy-ptt starting")
    while True:
        nodes = find_pedal_nodes()
        if not nodes:
            time.sleep(3)
            continue
        fds = open_and_grab(nodes)
        if not fds:
            time.sleep(3)
            continue
        log(f"grabbed {', '.join(fds.values())}")
        pump_events(fds)
        for fd in fds:
            os.close(fd)
        log("pedal disappeared; rescanning")
        time.sleep(1)


if __name__ == "__main__":
    main()
