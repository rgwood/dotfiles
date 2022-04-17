#!/usr/bin/env bash

# general system utils
sudo dnf install -y zsh bat fzf micro tealdeer htop ripgrep python3-pip gnome-tweaks

# for chsh
sudo dnf install -y util-linux-user

# for nushell development
sudo dnf install -y openssl-devel mold clang