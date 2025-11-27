#!/bin/bash

system.setup() {
  nvm.setup

  if ! command -v pnpm &> /dev/null; then
    log.info "Installing pnpm..."
    npm install -g pnpm
  fi
}

FLAG__FRESH_START=
bai.initial.install() {
  log.info "Performing fresh initial install of BAI..."
  FLAG__FRESH_START=true
  rm -f package-lock.json pnpm-lock.yaml
  folder.delete node_modules

  cat <<EOF >package.json
{
  "name": "temp",
  "version": "0.0.1",
  "devDependencies": {
    "tsx": "latest",
    "ts-node": "latest",
    "typescript": "latest",
    "firebase-tools": "latest",
    "@types/node": "^22.0.0",
    "@nu-art/build-and-install": "$TS_VERSION",
    "@nu-art/commando": "$TS_VERSION",
    "@nu-art/ts-common": "$TS_VERSION"
  }
}
EOF

  echo -e "packages:\n  - '.'" > pnpm-workspace.yaml

  pnpm install
}

bai.build.run() {
  log.debug "Launching BAI with params: $*"

  if [[ "$FLAG__FRESH_START" != "true" ]] && [[ -f "$REPO_ROOT/build-and-install.ts" ]]; then
#    export NODE_OPTIONS='--import data:text/javascript,import%20%7B%20register%20%7D%20from%20%22node%3Amodule%22%3B%20import%20%7B%20pathToFileURL%20%7D%20from%20%22node%3Aurl%22%3B%20register%28%22ts-node%2Fesm%22%2C%20pathToFileURL%28%22.%2F%22%29%29%3B'
    tsz "$REPO_ROOT/build-and-install.ts" "$@"
  else
    tsx "$(npm root)/@nu-art/build-and-install/build-and-install.js" "$@"
  fi
}

