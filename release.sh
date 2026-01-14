#!/bin/bash

source <(curl -fsSL https://github.com/nu-art/bash-tools/releases/latest/download/bundle.loader.sh?t=$(date +%s)) --sh-bundle release --sh-force "$@"