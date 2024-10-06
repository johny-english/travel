#!/bin/bash

THIS_DIR=$(cd "$(dirname "$0")"; pwd)

$THIS_DIR/install_fish_only.sh
fish $THIS_DIR/install_fish.fish "$@"
