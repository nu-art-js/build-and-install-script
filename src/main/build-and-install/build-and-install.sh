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
  "private": true,
  "type": "module",
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

## @function: bai.ssl.setup()
##
## @description: Setup SSL certificate for local development (creates, adds to keychain, and trusts)
##
## @return: void
bai.ssl.setup() {
  local CERT_NAME="${1:-localhost}"
  local DAYS="${2:-365}"
  
  log.info "Setting up SSL certificate for local development..."
  
  # Determine certificate paths
  local CERT_DIR="${SSL_CERT_DIR:-${REPO_ROOT}/.temp}"
  local CERT_PATH="${CERT_DIR}/${CERT_NAME}.crt"
  local KEY_PATH="${CERT_DIR}/${CERT_NAME}.key"
  
  # Ensure certificate directory exists
  folder.create "$CERT_DIR"
  
  # Step 1: Ensure certificate exists
  log.info "Step 1: Ensuring certificate exists..."
  if ! ssl.has_cert "$CERT_PATH"; then
    log.info "Certificate not found, creating..."
    ssl.ensure_cert "$KEY_PATH" "$CERT_PATH" "$DAYS" "$CERT_NAME" "localhost" "127.0.0.1"
  else
    log.debug "Certificate already exists: $CERT_PATH"
    ssl.ensure_cert "$KEY_PATH" "$CERT_PATH" "$DAYS" "$CERT_NAME" "localhost" "127.0.0.1"
  fi
  
  # Step 2: Add to keychain if not present
  log.info "Step 2: Checking if certificate is in keychain..."
  if ssl.is_cert_in_keychain "$CERT_PATH"; then
    log.debug "Certificate is already in keychain"
  else
    log.info "Certificate not in keychain, adding..."
    ssl.add_cert_to_keychain "$CERT_PATH"
  fi
  
  # Step 3: Trust certificate if not trusted
  log.info "Step 3: Ensuring certificate is trusted..."
  if ssl.is_cert_trusted "$CERT_PATH"; then
    log.debug "Certificate is already trusted"
  else
    log.info "Certificate not trusted, trusting..."
    ssl.trust_cert "$CERT_PATH"
  fi
  
  log.info "✅ SSL certificate setup complete"
}

bai.build.run() {
  log.debug "Launching BAI with params: $*"

  if [[ -f "$REPO_ROOT/build-and-install.ts" ]]; then
#    export NODE_OPTIONS='--import data:text/javascript,import%20%7B%20register%20%7D%20from%20%22node%3Amodule%22%3B%20import%20%7B%20pathToFileURL%20%7D%20from%20%22node%3Aurl%22%3B%20register%28%22ts-node%2Fesm%22%2C%20pathToFileURL%28%22.%2F%22%29%29%3B'
    ./node_modules/.bin/tsx "$REPO_ROOT/build-and-install.ts" "$@"
  else
    ./node_modules/.bin/tsx "$(npm root)/@nu-art/build-and-install/build-and-install.js" "$@"
  fi
}

