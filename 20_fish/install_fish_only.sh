#!/bin/bash

set -x
set +e

sudo apt update
sudo apt install -y git fish curl fonts-powerline
set -e

# TODO: switch to https://github.com/jorgebucaran/awsm.fish#readme ?
curl https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install > /tmp/install
echo "e5b0702f490d78f5e5e85e1593234cbac8f8c34c4d44babc726dd777fb93c21c /tmp/install" | sha256sum --check
fish /tmp/install --path=~/.local/share/omf --config=~/.config/omf --noninteractive --yes
rm /tmp/install
fish -c "omf install bobthefish"
mkdir -p ~/.config/fish/
set +x

echo "To make fish your default shell, issue: sudo chsh -s /usr/bin/fish \$(whoami)"
echo "To restore your default shell: chsh -s /bin/bash"
