#!/bin/bash

# Note: This file is used within a bundle context where lib.tools is already loaded
# The utilities (log) are provided by lib.tools bundle

ssl.print_help() {
  echo -e "\nSSL Certificate Setup Options:\n"
  echo "  <key_name> [days]     Setup SSL certificate (default: localhost 365)"
  echo "                        If .config/ssl-certs.conf has a [key_name] section,"
  echo "                        CN, SAN, and days are resolved from it automatically."
  echo "  --help, -h            Show this help message"
  echo
}

ssl.run() {
  # Default to setup if no arguments or if first arg doesn't look like a flag
  if [[ $# -eq 0 ]] || [[ "$1" != --* ]]; then
    ssl.setup "$@"
    exit 0
  fi
  
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --help|-h)
        ssl.print_help
        exit 0
        ;;
      *)
        log.error "Unknown option: $1"
        ssl.print_help
        exit 1
        ;;
    esac
  done
}

