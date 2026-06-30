#!/bin/bash
# SSL certificate setup script
# Creates certificate if missing or config changed, adds to keychain, and ensures trust.
# Resolves domain config from ssl-certs.conf when available.

set -e

CERT_NAME="${1:-localhost}"
DAYS="${2:-365}"

# Load bash-tools
source <(curl -fsSL https://github.com/nu-art/bash-tools/releases/latest/download/bundle.loader.sh) -b lib.tools

# Determine repo root
REPO_ROOT="$(folder.repo_root)"

# Default to .temp folder in repo root (gitignored)
# Can be overridden with SSL_CERT_DIR environment variable
CERT_DIR="${SSL_CERT_DIR:-${REPO_ROOT}/.temp}"
CERT_PATH="${CERT_DIR}/${CERT_NAME}.crt"
KEY_PATH="${CERT_DIR}/${CERT_NAME}.key"

# Resolve config: ssl-certs.conf section takes precedence, then defaults
CONFIG_CN="$CERT_NAME"
CONFIG_SAN=("localhost" "127.0.0.1")
CONFIG_DAYS="$DAYS"

_resolve_config() {
  local config_file="${REPO_ROOT}/.config/ssl-certs.conf"

  if [[ -f "$config_file" ]]; then
    local config_string
    config_string="$(_ssl.read_config "$CERT_NAME" 2>/dev/null)" || true

    if [[ -n "$config_string" ]]; then
      _ssl.parse_config "$config_string"
      CONFIG_CN="$SSL_CONFIG_CN"
      CONFIG_SAN=("${SSL_CONFIG_SAN[@]}")
      CONFIG_DAYS="$SSL_CONFIG_DAYS"
      log.info "Loaded certificate config from ssl-certs.conf [$CERT_NAME]"
    else
      log.debug "No config section [$CERT_NAME] in ssl-certs.conf, using defaults"
    fi
  else
    log.debug "No ssl-certs.conf found, using defaults"
  fi
}

step1_create_cert() {
  log.info "Step 1: Ensuring certificate exists and matches config..."
  ssl.ensure_cert "$KEY_PATH" "$CERT_PATH" "$CONFIG_DAYS" "$CONFIG_CN" "${CONFIG_SAN[@]}"
}

step2_add_to_keychain() {
  log.info "Step 2: Checking if certificate is in keychain..."

  if ssl.is_cert_in_keychain "$CERT_PATH"; then
    log.debug "Certificate is already in keychain"
  else
    log.info "Certificate not in keychain, adding..."
    ssl.add_cert_to_keychain "$CERT_PATH"
  fi
}

step3_trust_cert() {
  log.info "Step 3: Ensuring certificate is trusted..."

  if ssl.is_cert_trusted "$CERT_PATH"; then
    log.debug "Certificate is already trusted"
  else
    log.info "Certificate not trusted, trusting..."
    ssl.trust_cert "$CERT_PATH"
  fi
}

main() {
  _resolve_config

  log.info "SSL Certificate Setup"
  log.debug "Certificate name: $CERT_NAME"
  log.debug "CN: $CONFIG_CN"
  log.debug "SAN: ${CONFIG_SAN[*]}"
  log.debug "Validity: $CONFIG_DAYS days"
  log.debug "Certificate directory: $CERT_DIR"
  echo ""

  folder.create "$CERT_DIR"

  step1_create_cert
  step2_add_to_keychain
  step3_trust_cert

  log.info "✅ SSL certificate setup complete"
}

main "$@"