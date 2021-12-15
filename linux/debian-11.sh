#!/usr/bin/env bash

# essentials
sudo apt install git zsh rsync micro fzf curl wget -y

# nice to haves
sudo apt install mosh iotop python3-pip -y

# needed for some Cargo packages
sudo apt install build-essential llvm libclang-dev libssl-dev pkg-config -y