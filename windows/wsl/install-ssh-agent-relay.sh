#!/usr/bin/env bash

# warning: this is deprecated. but the recommended replacement won't work for me

sudo apt install daemonize socat -y
git clone https://github.com/anaisbetts/ssh-agent-relay
cd ssh-agent-relay
sudo make install