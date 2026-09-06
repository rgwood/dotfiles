# Linux setup

For Debian or Ubuntu, run `./linux/apt-packages.sh` to install system utilities
and native build dependencies. It replaces the separate Debian 11 package list.
Then run `./install` to link configs and install the remaining CLI tools.

For Fedora, use `./linux/fedora.sh` before `./install`.

The bootstrap installer tries all tools and exits with an error if any install
fails. It skips Rust and Node on machines with 2 GB of RAM or less and reports
those skips separately. Re-run `./install` after fixing a failure.

The scripts in `archive/` are historical references. They are unmaintained and
are not part of the install process.

Run `uv run tests/test_dotfiles.py` from the repository root to check bootstrap
failure handling and shell PATH ordering. These checks do not install packages
or change system settings. The PATH checks need both zsh and Nushell.
