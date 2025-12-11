#!/bin/bash
# SSL certificate setup script
# Creates certificate if missing, adds to keychain if not present, and ensures it's trusted

set -e

CERT_NAME="${1:-localhost}"
DAYS="${2:-365}"

# Load bash-tools
source <(curl -fsSL https://github.com/nu-art/bash-tools/releases/latest/download/bundle.loader.sh) -b lib.tools -f

# Determine repo root
REPO_ROOT="$(folder.repo_root)"

# Default to .temp folder in repo root (gitignored)
# Can be overridden with SSL_CERT_DIR environment variable
CERT_DIR="${SSL_CERT_DIR:-${REPO_ROOT}/.temp}"
CERT_PATH="${CERT_DIR}/${CERT_NAME}.crt"
KEY_PATH="${CERT_DIR}/${CERT_NAME}.key"

## @function: step1_create_cert()
##
## @description: Check if cert exists, if not create it with SAN entries for webpack/express compatibility
##
## @return: void
step1_create_cert() {
  log.info "Step 1: Ensuring certificate exists..."
  
  if ! ssl.has_cert "$CERT_PATH"; then
    log.info "Certificate not found, creating..."
    # Generate certificate with SAN entries for webpack and express compatibility
    # Includes localhost (DNS) and 127.0.0.1 (IP) in Subject Alternative Name
    ssl.ensure_cert "$KEY_PATH" "$CERT_PATH" "$DAYS" "$CERT_NAME" "localhost" "127.0.0.1"
  else
    log.debug "Certificate already exists: $CERT_PATH"
    # Still call ensure_cert to check expiration and regenerate if needed
    ssl.ensure_cert "$KEY_PATH" "$CERT_PATH" "$DAYS" "$CERT_NAME" "localhost" "127.0.0.1"
  fi
}

## @function: step2_add_to_keychain()
##
## @description: If cert is not in keychain, add it
##
## @return: void
step2_add_to_keychain() {
  log.info "Step 2: Checking if certificate is in keychain..."
  
  if ssl.is_cert_in_keychain "$CERT_PATH"; then
    log.debug "Certificate is already in keychain"
  else
    log.info "Certificate not in keychain, adding..."
    ssl.add_cert_to_keychain "$CERT_PATH"
  fi
}

## @function: step3_trust_cert()
##
## @description: If cert is not trusted, trust it
##
## @return: void
step3_trust_cert() {
  log.info "Step 3: Ensuring certificate is trusted..."
  
  if ssl.is_cert_trusted "$CERT_PATH"; then
    log.debug "Certificate is already trusted"
  else
    log.info "Certificate not trusted, trusting..."
    ssl.trust_cert "$CERT_PATH"
  fi
}

# Main execution
main() {
  log.info "SSL Certificate Setup"
  log.debug "Certificate name: $CERT_NAME"
  log.debug "Validity: $DAYS days"
  log.debug "Certificate directory: $CERT_DIR"
  echo ""

  # Ensure certificate directory exists
  folder.create "$CERT_DIR"
  
  step1_create_cert
  step2_add_to_keychain
  step3_trust_cert
  
  log.info "✅ SSL certificate setup complete"
}

# Run main function
main "$@"