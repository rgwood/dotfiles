#!/usr/bin/env python3
"""Ensure essential tools are installed. Runs during dotfiles bootstrap."""

from __future__ import annotations

import fnmatch
import json
import os
import platform
import shutil
import subprocess
import sys
import tarfile
import tempfile
import urllib.request
import zipfile
from pathlib import Path

HOME = Path.home()
BIN_DIR = HOME / "bin"

SYSTEM = platform.system()  # Darwin | Linux
MACHINE = platform.machine()  # x86_64 | aarch64 | arm64
IS_MAC = SYSTEM == "Darwin"
IS_LINUX = SYSTEM == "Linux"


def total_ram_gb() -> float:
    try:
        page_size = os.sysconf("SC_PAGE_SIZE")
        page_count = os.sysconf("SC_PHYS_PAGES")
        return (page_size * page_count) / (1024**3)
    except (ValueError, OSError):
        return 99.0  # assume plenty if we can't detect


def log(tag: str, msg: str) -> None:
    colors = {"ok": "\033[32m", "install": "\033[34m", "skip": "\033[33m", "fail": "\033[31m"}
    reset = "\033[0m"
    color = colors.get(tag, "")
    print(f"  {color}[{tag}]{reset} {msg}", file=sys.stderr)


def is_installed(cmds: list[str]) -> str | None:
    """Return the first found command name, or None."""
    for cmd in cmds:
        if shutil.which(cmd):
            return cmd
    return None


def run(args: list[str], **kwargs) -> subprocess.CompletedProcess:
    return subprocess.run(args, **kwargs)


def has_brew() -> bool:
    return shutil.which("brew") is not None


def has_apt() -> bool:
    return shutil.which("apt-get") is not None


def has_cargo() -> bool:
    return shutil.which("cargo") is not None


# ---------------------------------------------------------------------------
# Install methods
# ---------------------------------------------------------------------------


def install_via_brew(packages: list[str]) -> bool:
    result = run(["brew", "install"] + packages)
    return result.returncode == 0


def install_via_apt(packages: list[str]) -> bool:
    result = run(["sudo", "apt-get", "install", "-y"] + packages)
    return result.returncode == 0


def install_via_cargo(crate: str) -> bool:
    if not has_cargo():
        return False
    result = run(["cargo", "install", crate])
    return result.returncode == 0


def github_arch() -> str:
    """Return a short arch string for GitHub asset matching."""
    if MACHINE in ("arm64", "aarch64"):
        return "aarch64"
    return "x86_64"


def install_from_github(
    repo: str,
    asset_patterns: list[str],
    binary_name: str,
    install_dir: Path | None = None,
) -> bool:
    """Download latest release from GitHub, extract binary to install_dir."""
    install_dir = install_dir or BIN_DIR
    url = f"https://api.github.com/repos/{repo}/releases/latest"
    req = urllib.request.Request(url, headers={"Accept": "application/vnd.github.v3+json"})

    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            data = json.loads(resp.read())
    except Exception as e:
        log("fail", f"  could not fetch releases for {repo}: {e}")
        return False

    # find matching asset
    asset_url = None
    asset_name = None
    for asset in data.get("assets", []):
        for pattern in asset_patterns:
            if fnmatch.fnmatch(asset["name"], pattern):
                asset_url = asset["browser_download_url"]
                asset_name = asset["name"]
                break
        if asset_url:
            break

    if not asset_url:
        log("fail", f"  no matching asset for {repo} (patterns: {asset_patterns})")
        return False

    with tempfile.TemporaryDirectory() as tmpdir:
        archive_path = os.path.join(tmpdir, asset_name)
        try:
            urllib.request.urlretrieve(asset_url, archive_path)
        except Exception as e:
            log("fail", f"  download failed for {repo}: {e}")
            return False

        # extract binary
        dest = install_dir / binary_name
        try:
            if asset_name.endswith(".tar.gz") or asset_name.endswith(".tgz"):
                with tarfile.open(archive_path) as tar:
                    for member in tar.getmembers():
                        if member.name.endswith(f"/{binary_name}") or member.name == binary_name:
                            f = tar.extractfile(member)
                            if f:
                                dest.write_bytes(f.read())
                                dest.chmod(0o755)
                                return True
            elif asset_name.endswith(".zip"):
                with zipfile.ZipFile(archive_path) as zf:
                    for name in zf.namelist():
                        if name.endswith(f"/{binary_name}") or name == binary_name:
                            dest.write_bytes(zf.read(name))
                            dest.chmod(0o755)
                            return True
        except Exception as e:
            log("fail", f"  extraction failed for {repo}: {e}")
            return False

    log("fail", f"  binary '{binary_name}' not found in archive from {repo}")
    return False


def install_via_script(url: str, args: list[str] | None = None) -> bool:
    """Download and run an install script."""
    try:
        req = urllib.request.Request(url)
        with urllib.request.urlopen(req, timeout=30) as resp:
            script = resp.read()
    except Exception as e:
        log("fail", f"  could not fetch {url}: {e}")
        return False

    cmd = ["bash", "-s", "--"] + (args or [])
    result = run(cmd, input=script)
    return result.returncode == 0


def ensure_symlink(link: Path, target: str) -> None:
    """Create ~/bin symlink for tools installed under different names (batcat, fdfind)."""
    real = shutil.which(target)
    if real and not link.exists():
        link.symlink_to(real)
        log("ok", f"  symlinked {link.name} -> {real}")


# ---------------------------------------------------------------------------
# Bootstrap: brew, rust/cargo
# ---------------------------------------------------------------------------

def ensure_brew() -> bool:
    if has_brew():
        log("ok", "homebrew already installed")
        return True
    log("install", "installing homebrew...")
    ok = install_via_script("https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh")
    if ok:
        # add brew to PATH for the rest of this script
        for p in ["/opt/homebrew/bin", "/usr/local/bin"]:
            if os.path.isfile(f"{p}/brew"):
                os.environ["PATH"] = f"{p}:{os.environ['PATH']}"
                break
        log("ok", "homebrew installed")
    else:
        log("fail", "homebrew installation failed")
    return ok


def ensure_rust() -> bool:
    if is_installed(["cargo"]):
        log("ok", "rust/cargo already installed")
        return True

    ram = total_ram_gb()
    if ram <= 2.0:
        log("skip", f"rust/cargo (only {ram:.1f}GB RAM)")
        return False

    log("install", "installing rust via rustup...")
    ok = install_via_script("https://sh.rustup.rs", ["-y"])
    if ok:
        cargo_bin = str(HOME / ".cargo" / "bin")
        os.environ["PATH"] = f"{cargo_bin}:{os.environ['PATH']}"
        log("ok", "rust/cargo installed")
    else:
        log("fail", "rust installation failed")
    return ok


def ensure_uv() -> bool:
    if is_installed(["uv"]):
        log("ok", "uv already installed")
        return True

    if IS_MAC and has_brew():
        log("install", "installing uv via brew...")
        if install_via_brew(["uv"]):
            log("ok", "uv installed")
            return True

    log("install", "installing uv via install script...")
    ok = install_via_script("https://astral.sh/uv/install.sh")
    if ok:
        # uv installs to ~/.local/bin or ~/.cargo/bin
        for p in [str(HOME / ".local" / "bin"), str(HOME / ".cargo" / "bin")]:
            if os.path.isfile(f"{p}/uv"):
                os.environ["PATH"] = f"{p}:{os.environ['PATH']}"
                break
        log("ok", "uv installed")
    else:
        log("fail", "uv installation failed")
    return ok


def ensure_node() -> bool:
    if is_installed(["node"]):
        log("ok", "node already installed")
        return True

    ram = total_ram_gb()
    if ram <= 2.0:
        log("skip", f"node/npm (only {ram:.1f}GB RAM)")
        return False

    # Install Volta (Node version manager), then use it to install Node
    if not is_installed(["volta"]):
        log("install", "installing volta (node version manager)...")
        # Volta's install script uses curl internally, so we can't pipe it via
        # stdin like install_via_script does. Download to a temp file instead.
        with tempfile.NamedTemporaryFile(suffix=".sh", delete=False) as f:
            try:
                urllib.request.urlretrieve("https://get.volta.sh", f.name)
            except Exception as e:
                log("fail", f"could not fetch volta installer: {e}")
                return False
            result = run(["bash", f.name, "--skip-setup"])
            os.unlink(f.name)
        if result.returncode != 0:
            log("fail", "volta installation failed")
            return False
        volta_bin = str(HOME / ".volta" / "bin")
        os.environ["PATH"] = f"{volta_bin}:{os.environ['PATH']}"
        log("ok", "volta installed")

    log("install", "installing node via volta...")
    result = run(["volta", "install", "node"])
    if result.returncode == 0:
        log("ok", "node/npm installed")
        return True
    else:
        log("fail", "node installation failed")
        return False


# ---------------------------------------------------------------------------
# Tool definitions
# ---------------------------------------------------------------------------

ARCH = github_arch()

# Each tool: (name, check_cmds, mac_brew_pkg, linux_methods)
# linux_methods is a list of callables returning bool, tried in order
TOOLS: list[dict] = [
    {
        "name": "bat",
        "check": ["bat", "batcat"],
        "brew": "bat",
        "linux": [
            lambda: install_via_apt(["bat"]),
            lambda: install_from_github(
                "sharkdp/bat",
                [f"bat-*-{ARCH}-unknown-linux-musl.tar.gz", f"bat-*-{ARCH}-unknown-linux-gnu.tar.gz"],
                "bat",
            ),
        ],
        "post": lambda: ensure_symlink(BIN_DIR / "bat", "batcat"),
    },
    {
        "name": "fd",
        "check": ["fd", "fdfind"],
        "brew": "fd",
        "linux": [
            lambda: install_via_apt(["fd-find"]),
            lambda: install_from_github(
                "sharkdp/fd",
                [f"fd-*-{ARCH}-unknown-linux-musl.tar.gz", f"fd-*-{ARCH}-unknown-linux-gnu.tar.gz"],
                "fd",
            ),
        ],
        "post": lambda: ensure_symlink(BIN_DIR / "fd", "fdfind"),
    },
    {
        "name": "micro",
        "check": ["micro"],
        "brew": "micro",
        "linux": [
            lambda: install_via_apt(["micro"]),
            lambda: install_from_github(
                "zyedidia/micro",
                [f"micro-*-linux64.tar.gz"] if ARCH == "x86_64" else [f"micro-*-linux-arm64.tar.gz"],
                "micro",
            ),
        ],
    },
    {
        "name": "lazygit",
        "check": ["lazygit"],
        "brew": "lazygit",
        "linux": [
            lambda: install_from_github(
                "jesseduffield/lazygit",
                [f"lazygit_*_linux_arm64.tar.gz"]
                if ARCH == "aarch64"
                else [f"lazygit_*_linux_x86_64.tar.gz"],
                "lazygit",
            ),
        ],
    },
    {
        "name": "nushell",
        "check": ["nu"],
        "brew": "nushell",
        "linux": [
            lambda: install_from_github(
                "nushell/nushell",
                [f"nu-*-{ARCH}-unknown-linux-musl.tar.gz", f"nu-*-{ARCH}-unknown-linux-gnu.tar.gz"],
                "nu",
            ),
        ],
    },
]


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------


def main() -> None:
    print("ensuring essential tools are installed...", file=sys.stderr)

    BIN_DIR.mkdir(parents=True, exist_ok=True)
    failures: list[str] = []

    # Phase 1: bootstraps
    if IS_MAC:
        ensure_brew()

    ensure_rust()
    ensure_uv()
    ensure_node()

    # Phase 2: tools
    if IS_MAC and has_brew():
        # batch brew install for speed
        to_install = []
        for tool in TOOLS:
            found = is_installed(tool["check"])
            if found:
                log("ok", f"{tool['name']} already installed ({found})")
            else:
                to_install.append(tool)

        if to_install:
            names = [t["brew"] for t in to_install]
            log("install", f"installing via brew: {', '.join(names)}...")
            if install_via_brew(names):
                for tool in to_install:
                    log("ok", f"{tool['name']} installed")
            else:
                # try individually so partial success works
                for tool in to_install:
                    if not install_via_brew([tool["brew"]]):
                        log("fail", f"{tool['name']}")
                        failures.append(tool["name"])
                    else:
                        log("ok", f"{tool['name']} installed")

    elif IS_LINUX:
        apt_updated = False
        for tool in TOOLS:
            found = is_installed(tool["check"])
            if found:
                log("ok", f"{tool['name']} already installed ({found})")
                if "post" in tool:
                    tool["post"]()
                continue

            installed = False
            for method in tool["linux"]:
                # run apt-get update once before first apt install
                if not apt_updated and has_apt():
                    run(["sudo", "apt-get", "update", "-qq"])
                    apt_updated = True
                if method():
                    log("ok", f"{tool['name']} installed")
                    installed = True
                    break

            if installed and "post" in tool:
                tool["post"]()
            if not installed:
                log("fail", f"{tool['name']} could not be installed")
                failures.append(tool["name"])

    if failures:
        print(f"\nfailed to install: {', '.join(failures)}", file=sys.stderr)
        # don't exit non-zero -- best effort
    else:
        print("all tools installed!", file=sys.stderr)


if __name__ == "__main__":
    main()
