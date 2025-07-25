#!/bin/bash

TS_VERSION=0.300.8
NODE_MODULES_DIR="$(pwd)/node_modules"

initial.build() {
  [[ ! ${freshStart} && -e "./package.json" ]] && return

  rm -f package-lock.json pnpm-lock.yaml
  rm -rf node_modules
  additionalFlags+='-p -ip'

  cat <<EOF > package.json
{
  "name": "temp",
  "version": "0.0.1",
  "devDependencies": {
    "ts-node": "latest",
    "typescript": "latest",
    "firebase-tools": "latest",
    "@types/node": "^22.0.0",
    "@nu-art/build-and-install": "${TS_VERSION}",
    "@nu-art/commando": "${TS_VERSION}",
    "@nu-art/ts-common": "${TS_VERSION}"
  }
}
EOF

  echo "packages:\n  - '.'" > pnpm-workspace.yaml
  pnpm install

  backup.modules
  echo "stable" > "$NODE_MODULES_DIR/.source"
}

build.project() {
  if [[ -e "./build-and-install.ts" ]]; then
    ts-node ./build-and-install.ts "$@" $additionalFlags
  else
    ts-node $(npm root)/@nu-art/build-and-install/build-and-install.js "$@" $additionalFlags
  fi
}


