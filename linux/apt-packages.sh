#!/usr/bin/env bash
# Install packages that are commonly available via APT in the distros I use

sudo apt install fish mosh iotop python3-pip

# not always available...
sudo apt install fzf

# gcc etc, needed for cargo
sudo apt install build-essential

# needed for some Cargo packages
sudo apt install llvm libclang-dev libssl-dev pkg-config