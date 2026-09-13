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

## Taildrop

To save incoming files automatically, `taildrop.service` runs Tailscale's built-in
receive loop as your user. Files go into `~/Downloads/Taildrop`, belong to you,
and are private to your account. Duplicate names get a numbered suffix.
The loop waits on the local daemon when idle and backs off on errors.

Install Tailscale first, then run `./install` to link the service. Enable it once
on each Linux machine where you want automatic receiving:

```sh
sudo tailscale set --operator="$USER"
systemctl --user daemon-reload
systemctl --user enable --now taildrop.service
```

The operator setting lets your account manage Tailscale without sudo, including
its settings. The service starts with your systemd user manager (normally at
login) and creates the destination directory if needed.

Check it with `systemctl --user status taildrop.service` or
`journalctl --user -u taildrop.service`. To stop automatic receiving, run
`systemctl --user disable --now taildrop.service`.
