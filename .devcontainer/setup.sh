#!/bin/bash

sudo apt-get update
sudo apt-get install -y lastpass-cli

curl -L https://fly.io/install.sh | sh

cat >> ~/.bashrc << EOM
export FLYCTL_INSTALL="/home/vscode/.fly"
export PATH="/home/vscode/.fly/bin:$PATH"
EOM

cd /workspace/summarize
bundle