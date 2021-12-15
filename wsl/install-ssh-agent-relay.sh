#!/usr/bin/env bash

sudo apt install daemonize socat -y
git clone https://github.com/anaisbetts/ssh-agent-relay
cd ssh-agent-relay
sudo make install