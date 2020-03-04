#!/usr/bin/env bash
# Install packages that are commonly available via APT in the distros I use

sudo apt install fish mosh iotop fzf bfs python3-pip

# gcc etc, needed for cargo
sudo apt install build-essential

# needed for some Cargo packages
sudo apt install llvm libclang-dev