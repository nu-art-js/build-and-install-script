#!/bin/bash

# Note: This file is used within a bundle context where lib.tools is already loaded
# The utilities (log) are provided by lib.tools bundle

## @function: ssl.print_help()
##
## @description: Print help message for SSL commands
ssl.print_help() {
  echo -e "\nSSL Certificate Generation Options:\n"
  echo "  generate, gen, g    Generate SSL certificates and create symlinks"
  echo "  trust, t             Trust the certificate in system keychain"
  echo "  clean, c             Remove SSL certificates and symlinks"
  echo "  --help, -h           Show this help message"
  echo
}

## @function: ssl.generate(key_name?, days?)
##
## @description: Generate SSL certificates and create symlinks
##
## @param: $1 - Optional key/cert name (default: localhost)
## @param: $2 - Optional number of days validity (default: 365)
ssl.generate() {
  local key_name="${1:-localhost}"
  local days="${2:-365}"
  
  ssl.setup "$key_name" "$days"
}

## @function: ssl.trust(key_name?)
##
## @description: Trust the certificate in system keychain
##
## @param: $1 - Optional key/cert name (default: localhost)
ssl.trust() {
  local key_name="${1:-localhost}"
  
  # Allow override via environment variable for testing
  local cert_dir="${SSL_CERT_DIR:-${HOME}/.local-dev-cert}"
  local cert_path="${cert_dir}/${key_name}.crt"
  
  if [[ ! -f "$cert_path" ]]; then
    log.error "Certificate not found: $cert_path"
    log.info "Run 'ssl.generate' first to create the certificate"
    exit 1
  fi
  
  ssl.trust_cert "$cert_path"
}

## @function: ssl.run(...args)
##
## @description: CLI entry point for SSL commands
##
## @param: $@ - Command and arguments
ssl.run() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      generate|gen|g)
        shift
        ssl.generate "$@"
        exit 0
        ;;
      trust|t)
        shift
        ssl.trust "$@"
        exit 0
        ;;
      clean|c)
        shift
        ssl.clean "$@"
        exit 0
        ;;
      --help|-h)
        ssl.print_help
        exit 0
        ;;
      *)
        log.error "Unknown command: $1"
        ssl.print_help
        exit 1
        ;;
    esac
  done
  
  # Default action if no command provided
  ssl.print_help
  exit 0
}

