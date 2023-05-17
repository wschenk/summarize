#!/bin/bash

# Install last-pass if needed
sudo apt-get update && sudo apt-get install -y lastpass-cli

# Install fly-io
curl -L https://fly.io/install.sh | sh

cat >> ~/.bashrc << EOM
export FLYCTL_INSTALL="/home/vscode/.fly"
export PATH="/home/vscode/.fly/bin:$PATH"
EOM

# Run bundle
bundle

# Install node awesome

npm i