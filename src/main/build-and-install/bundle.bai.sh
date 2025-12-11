#!/bin/bash

## Bundle: bootstrap
## Description: Thunderstorm setup and patch utilities
source <(curl -fsSL https://github.com/nu-art/bash-tools/releases/latest/download/bundle.loader.sh) -b lib.tools -f

import "./backup.sh"
import "./build-and-install.sh"
import "./cli.sh"
# SSL functions are provided by lib.tools bundle (ssl.setup, ssl.generate_cert, etc.)


#log.debug "Running Bundle: $BUNDLE_NAME v$BUNDLE_VERSION"
log.debug "BAI received params: $*"
bai.run "$@"

