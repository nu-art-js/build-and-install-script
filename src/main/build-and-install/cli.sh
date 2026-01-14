#!/bin/bash

BAI_REMAINING_ARGS=()

bai.print_help() {
  echo -e "\nThunderstorm BAI Script Options:\n"
  echo "  init                      Full initialization (removes node_modules, sets up SSL, installs deps)"
  echo "  ssl [name] [days]         Setup SSL certificate only (fast, for testing)"
  echo "  --ts-version=<pattern>, -tv=<pattern>  Desired version pattern (e.g., ~0.400.0, ^0.400.0, or exact version)"
  echo "  --backup <label>, -b      Backup current node_modules under the given label (default if omitted)"
  echo "  --restore <label>, -r     Restore node_modules from the given label (default if omitted)"
  echo "  --local, -l               Inject dist folders from _thunderstorm packages"
  echo "  --list                    List available backup labels"
  echo "  --help-bai, -hb           Show this help message"
  echo
}

TS_DESIRED_VERSION="~0.401.0"

bai.run() {
  REPO_ROOT="$(folder.repo_root)"

  system.setup

  # Process configuration flags (extract --ts-version before TS_VERSION resolution)
  for arg in "$@"; do
    case "$arg" in
      --ts-version=*|-tsv=*)
        TS_DESIRED_VERSION="${arg#*=}"
        log.debug "TS_DESIRED_VERSION set from CLI flag: $TS_DESIRED_VERSION"
        ;;
    esac
  done

  # Resolve TS_VERSION: check environment variable first, then query npm registry
  if [[ -z "$TS_VERSION" ]]; then
    # npm view with range returns all matching versions as JSON array, extract the last one (latest)
    TS_VERSION="$(npm view @nu-art/ts-common@${TS_DESIRED_VERSION} version --json 2>/dev/null | grep -o '"[0-9.]*"' | tail -1 | tr -d '"')"
    if [[ -z "$TS_VERSION" ]]; then
      error.throw "No matching version found for pattern '$TS_DESIRED_VERSION' in package @nu-art/ts-common. Please check the version pattern and try again." 1
    fi
    log.debug "Resolved TS_VERSION from npm registry: $TS_VERSION"
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
