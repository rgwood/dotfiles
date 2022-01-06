#!/usr/bin/env bash

# essentials
sudo apt install git zsh rsync micro curl fzf wget -y

# nice to haves
sudo apt install mosh iotop python3-pip sh -y

# needed for some Cargo packages
sudo apt install build-essential llvm libclang-dev libssl-dev pkg-config -y


# Install .NET
# TODO update this when Microsoft publishes 21.10 version, but this works for now
wget https://packages.microsoft.com/config/ubuntu/21.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb

sudo apt-get update; \
  sudo apt-get install -y apt-transport-https && \
  sudo apt-get update && \
  sudo apt-get install -y dotnet-sdk-6.0