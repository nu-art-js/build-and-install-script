#!/bin/bash

## Bundle: ssl
## Description: SSL certificate generation and trust utilities for local development
source <(curl -fsSL https://github.com/nu-art/bash-tools/releases/latest/download/bundle.loader.sh) -b lib.tools -f

# SSL functions are provided by lib.tools bundle (ssl.setup, ssl.generate_cert, etc.)
import "./cli.sh"
import "./ssl.sh"

#log.debug "Running Bundle: $BUNDLE_NAME v$BUNDLE_VERSION"
log.debug "SSL bundle received params: $*"
ssl.run "$@"

