#!/bin/bash

system.setup() {
  nvm.setup

  if ! command -v pnpm &> /dev/null; then
    log.info "Installing pnpm..."
    npm install -g pnpm
  fi
}

bai.initial.install() {
  log.info "Performing fresh initial install of BAI..."

  rm -f package-lock.json pnpm-lock.yaml
  folder.delete node_modules

  cat <<EOF >package.json
{
  "name": "temp",
  "version": "0.0.1",
  "devDependencies": {
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
  additionalFlags+='-p -ip'

  pnpm install
  bai.backup
  echo "stable" > node_modules/.source
}

bai.build.run() {
  if [[ -f "./build-and-install.ts" ]]; then
    ts-node ./build-and-install.ts -th -cox "$additionalFlags" "$@"
  else
    ts-node "$(npm root)/@nu-art/build-and-install/build-and-install.js" -th -cox "$additionalFlags" "$@"
  fi
}

