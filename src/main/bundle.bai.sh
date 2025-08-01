#!/bin/bash

## Bundle: bootstrap
## Description: Thunderstorm setup and patch utilities
source <(curl -fsSL https://github.com/nu-art/bash-tools/releases/latest/download/bundle.loader.sh) -b lib.tools -f

import "./backup.sh"
import "./build-and-install.sh"
import "./cli.sh"

bai.run "$@"

