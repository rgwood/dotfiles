#!/usr/bin/env bash
# Shared Debian/Ubuntu packages; run ./install afterwards for the remaining CLI tools.
exec sudo apt-get install -y git zsh rsync micro curl wget unrar mosh iotop python3-pip build-essential llvm libclang-dev libssl-dev pkg-config
