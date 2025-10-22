#!/bin/bash

BAI_REMAINING_ARGS=()

bai.print_help() {
  echo -e "\nThunderstorm BAI Script Options:\n"
  echo "  --fresh-start, -fs        Run a clean install and immediately back it up"
  echo "  --backup <label>, -b      Backup current node_modules under the given label (default if omitted)"
  echo "  --restore <label>, -r     Restore node_modules from the given label (default if omitted)"
  echo "  --local, -l               Inject dist folders from _thunderstorm packages"
  echo "  --list                    List available backup labels"
  echo "  --help-bai, -hb           Show this help message"
  echo
}

bai.run() {
  TS_VERSION=0.300.8
  FRESH_START=false
  REPO_ROOT="$(folder.repo_root)"

  system.setup

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --fresh-start|-fs)
        ADDITIONAL_FLAGS+='-p -ip'
        bai.initial.install
        bai.backup "default"
        break
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
