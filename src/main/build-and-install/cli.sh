#!/bin/bash

BAI_REMAINING_ARGS=()

bai.print_help() {
  echo -e "\nThunderstorm BAI Script Options:\n"
  echo "  init                      Full initialization (removes node_modules, sets up SSL, installs deps)"
  echo "  ssl [name] [days]         Setup SSL certificate only (fast, for testing)"
  echo "  --backup <label>, -b      Backup current node_modules under the given label (default if omitted)"
  echo "  --restore <label>, -r     Restore node_modules from the given label (default if omitted)"
  echo "  --local, -l               Inject dist folders from _thunderstorm packages"
  echo "  --list                    List available backup labels"
  echo "  --help-bai, -hb           Show this help message"
  echo
}

bai.run() {
  REPO_ROOT="$(folder.repo_root)"

  system.setup

  # Resolve TS_VERSION: check environment variable first, then query npm registry
  if [[ -z "$TS_VERSION" ]]; then
    TS_VERSION="$(npm show @nu-art/ts-common version 2>/dev/null)"
    if [[ -z "$TS_VERSION" ]]; then
      TS_VERSION="0.400.8"
      log.warning "Failed to query npm registry for @nu-art/ts-common version, using fallback: $TS_VERSION"
    else
      log.debug "Resolved TS_VERSION from npm registry: $TS_VERSION"
    fi
  else
    log.debug "Using TS_VERSION from environment: $TS_VERSION"
  fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
      init)
        BAI_REMAINING_ARGS+=("-p")
        rm -rf "$REPO_ROOT/node_modules"
        bai.ssl.setup
        bai.initial.install
        bai.backup "default"
        shift
        ;;
      ssl)
        # Setup SSL certificate only (fast, for testing)
        # Accepts optional cert name and days as arguments
        shift
        local cert_name="${1:-localhost}"
        local days="${2:-365}"
        bai.ssl.setup "$cert_name" "$days" "system" "true"
        exit $? # Exit with the return code of ssl.setup
        ;;
      --backup)
        if [[ -n "$2" && "$2" != --* ]]; then
          BACKUP_LABEL="$2"
          shift 2
        else
          BACKUP_LABEL="default"
          shift
        fi
        bai.backup "$BACKUP_LABEL"
        exit 0
        ;;
      --restore)
        if [[ -n "$2" && "$2" != --* ]]; then
          RESTORE_LABEL="$2"
          shift 2
        else
          RESTORE_LABEL="default"
          shift
        fi
        bai.restore "$RESTORE_LABEL"
        exit 0
        ;;
      --local)
        bai.swap.local
        exit 0
        ;;
      --list)
        bai.list.backups
        exit 0
        ;;
      --help-bai|-hb)
        bai.print_help
        exit 0
        ;;
      *) # collect remaining
        BAI_REMAINING_ARGS+=("$1")
        shift
        ;;
    esac
  done

  bai.build.run "${BAI_REMAINING_ARGS[@]}"
}
