#!/bin/bash

set -x
set +e

sudo apt update
sudo apt install -y git fish curl fonts-powerline
set -e

# TODO: switch to https://github.com/jorgebucaran/awsm.fish#readme ?
curl --insecure -L https://get.oh-my.fish > /tmp/install
echo "429a76e5b5e692c921aa03456a41258b614374426f959535167222a28b676201 /tmp/install" | sha256sum --check
fish /tmp/install --path=~/.local/share/omf --config=~/.config/omf --noninteractive --yes
rm /tmp/install
fish -c "omf install bobthefish"
mkdir -p ~/.config/fish/
set +x

echo "To make fish your default shell, issue: sudo chsh -s /usr/bin/fish \$(whoami)"
echo "To restore your default shell: chsh -s /bin/bash"
