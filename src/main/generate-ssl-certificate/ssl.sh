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
  # Skip SSL setup when running as Jenkins user (CI/CD environment)
  local current_user="${USER:-$(whoami)}"
  if [[ "$current_user" == "jenkins" ]]; then
    log.info "Skipping SSL certificate setup (running as Jenkins user in CI/CD environment)"
    return 0
  fi
  
  local CERT_NAME="${1:-localhost}"
  local DAYS="${2:-365}"
  local KEYCHAIN_TYPE="${3:-system}"
  
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

  # Debounce logic: skip global cert/keychain setup if within one week, unless forced
  local SYNC_FILE="${CERT_DIR}/${CERT_NAME}.sync"
  local FORCE_FLAG="${4:-false}"

  if ssl.debounce_setup "$SYNC_FILE" "$FORCE_FLAG"; then
    # Step 1: Ensure certificate exists
    log.info "Step 1: Ensuring certificate exists..."
    if ! ssl.has_cert "$CERT_PATH"; then
      log.info "Certificate not found, creating..."
      ssl.ensure_cert "$KEY_PATH" "$CERT_PATH" "$DAYS" "$CERT_NAME" "localhost" "127.0.0.1"
    else
      log.debug "Certificate already exists: $CERT_PATH"
      ssl.ensure_cert "$KEY_PATH" "$CERT_PATH" "$DAYS" "$CERT_NAME" "localhost" "127.0.0.1"
    fi

    # Check if certificate is expiring soon (within 14 days)
    if ssl.has_cert "$CERT_PATH"; then
      if ssl.is_cert_expired_or_expiring "$CERT_PATH" "14"; then
        log.info "Certificate is expired or will expire within 14 days. Removing and regenerating..."
        rm -f "$CERT_PATH" "$KEY_PATH"
        ssl.setup "$CERT_NAME" "$DAYS" "$KEYCHAIN_TYPE"
        exit $?
      fi
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

    # Update debounce timestamp only after successful global setup
    date +%s > "$SYNC_FILE"
  fi

  # Step 4: Always create symlinks in project directory (project-scoped, not debounced)
  log.info "Step 4: Creating symlinks in project directory..."
  local REPO_ROOT
  REPO_ROOT="$(folder.repo_root)"
  local PROJECT_SSL_DIR="${REPO_ROOT}/.config/.ssl"

  folder.create "$PROJECT_SSL_DIR"

  symlink.ensure "$CERT_PATH" "${PROJECT_SSL_DIR}/${CERT_NAME}.crt"
  symlink.ensure "$KEY_PATH" "${PROJECT_SSL_DIR}/${CERT_NAME}.key"

  log.info "✅ SSL certificate setup complete"
  log.info "   Source of truth: $CERT_DIR"
  log.info "   Project symlinks: $PROJECT_SSL_DIR"
}


## @function: ssl.debounce_setup(sync_file, force?)
##
## @description: Checks if SSL certificate setup should be debounced (run at most once every 7 days, unless forced). Does not set the timestamp - that is done only after successful completion.
##
## @param: $1 - Path to the sync timestamp file (e.g., "${CERT_NAME}.sync")
## @param: $2 - Optional force flag ("true" to skip debounce; default: false)
##
## @return: 0 if setup should proceed, 1 if within debounce window and not forced
##
## @example: ssl.debounce_setup "$SYNC_TIMESTAMP_FILE" "$FORCE" || return 0
##
## @note: Only checks the timestamp; does not update it. Timestamp is set after successful completion in ssl.setup.
##
## @dependencies: log
ssl.debounce_setup() {
  local sync_file="$1"
  local force="${2:-false}"

  if [[ -z "$sync_file" ]]; then
    error.throw "Missing argument: sync_file" 1
  fi

  # If forced, always proceed (don't check debounce)
  if [[ "$force" == "true" ]]; then
    return 0
  fi

  local now_ts last_ts seven_days delta
  now_ts="$(date +%s)"
  seven_days=$((7 * 24 * 60 * 60))

  if [[ -f "$sync_file" ]]; then
    last_ts="$(cat "$sync_file" 2>/dev/null || echo 0)"
    delta=$((now_ts - last_ts))
    if [[ "$delta" -lt "$seven_days" ]]; then
      log.info "SSL certificate setup is debounced; last sync less than 7 days ago (use FORCE to override)."
      return 1
    fi
  fi

  # Proceed with setup (timestamp will be set after successful completion)
  return 0
}
