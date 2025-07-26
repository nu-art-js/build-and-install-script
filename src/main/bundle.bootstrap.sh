#!/bin/bash

## Bundle: bootstrap
## Description: Thunderstorm setup and patch utilities
source <(curl -fsSL https://github.com/nu-art/bash-tools/releases/latest/download/bundle.loader.sh) -b tools

import "./build.ts.sh"
import "./manipulator.sh"
import "./backup.sh"

for arg in "$@"; do
  if [[ $arg == "--fresh-start" || $arg == "-fs" ]]; then
    freshStart=true
  fi
done

main() {
  node.ensure_nvm || node.install_nvm
  node.ensure

  parse.flags "$@"
  initial.build
  manipulate.build "$1"
  build.project "$@"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi



