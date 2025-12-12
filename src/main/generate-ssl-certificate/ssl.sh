## @function: ssl.setup(cert_name?, days?, keychain_type?)
##
## @description: Complete SSL certificate setup for local development. Creates certificate if missing, adds to keychain if not present, and ensures it's trusted. Uses encapsulated SSL APIs.
##
## @param: $1 - Optional certificate name (default: localhost)
## @param: $2 - Optional number of days validity (default: 365)
## @param: $3 - Optional keychain type: "login" (default, no sudo) or "system" (requires sudo)
##
## @return: null
ssl.setup() {
  local CERT_NAME="${1:-localhost}"
  local DAYS="${2:-365}"
  local KEYCHAIN_TYPE="${3:-login}"
  
  log.info "Setting up SSL certificate for local development..."
  
  # Determine certificate paths
  # Source of truth: ~/.local-dev-ssl/ (see .project/conventions/ssl-certificate-storage.txt)
  local CERT_DIR="${SSL_CERT_DIR:-${HOME}/.local-dev-ssl}"
  local CERT_PATH="${CERT_DIR}/${CERT_NAME}.crt"
  local KEY_PATH="${CERT_DIR}/${CERT_NAME}.key"
  
  log.debug "Certificate name: $CERT_NAME"
  log.debug "Validity: $DAYS days"
  log.debug "Keychain type: $KEYCHAIN_TYPE"
  log.debug "Certificate directory: $CERT_DIR"
  echo ""
  
  # Ensure certificate directory exists
  folder.create "$CERT_DIR"
  
  # Step 1: Ensure certificate exists
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
  
  # Step 2: Add to keychain if not present
  log.info "Step 2: Checking if certificate is in keychain..."
  if ssl.is_cert_in_keychain "$CERT_PATH" "$KEYCHAIN_TYPE"; then
    log.debug "Certificate is already in keychain"
  else
    log.info "Certificate not in keychain, adding..."
    ssl.add_cert_to_keychain "$CERT_PATH" "$KEYCHAIN_TYPE"
  fi
  
  # Step 3: Trust certificate if not trusted
  log.info "Step 3: Ensuring certificate is trusted..."
  if ssl.is_cert_trusted "$CERT_PATH" "$KEYCHAIN_TYPE"; then
    log.debug "Certificate is already trusted"
  else
    log.info "Certificate not trusted, trusting..."
    ssl.trust_cert "$CERT_PATH" "$KEYCHAIN_TYPE"
  fi
  
  # Step 4: Create symlinks in project .config/.ssl/ directory
  log.info "Step 4: Creating symlinks in project directory..."
  local REPO_ROOT
  REPO_ROOT="$(folder.repo_root)"
  local PROJECT_SSL_DIR="${REPO_ROOT}/.config/.ssl"
  
  # Create .config/.ssl directory if it doesn't exist
  folder.create "$PROJECT_SSL_DIR"
  
  # Create symlinks for certificate and key
  local PROJECT_CERT_PATH="${PROJECT_SSL_DIR}/${CERT_NAME}.crt"
  local PROJECT_KEY_PATH="${PROJECT_SSL_DIR}/${CERT_NAME}.key"
  
  # Use symlink.ensure to create/update symlinks (from bash-tools)
  # This ensures symlinks point to the correct source of truth
  symlink.ensure "$CERT_PATH" "$PROJECT_CERT_PATH"
  symlink.ensure "$KEY_PATH" "$PROJECT_KEY_PATH"
  
  log.info "✅ SSL certificate setup complete"
  log.info "   Source of truth: $CERT_DIR"
  log.info "   Project symlinks: $PROJECT_SSL_DIR"
}