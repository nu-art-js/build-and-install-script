#!/bin/bash

bai.run() {
  TS_VERSION=0.300.8
  freshStart=false
  REPO_ROOT="$(folder.repo_root)"

  for arg in "$@"; do
    case "$arg" in
      --fresh-start|-fs) freshStart=true ;;
    esac
    [[ "$arg" == -*bai* ]] && swapMode="$arg"
  done

  if [[ ! -e "./package.json" ]]; then
    freshStart=true
  fi

  system.setup
  [[ $freshStart == true ]] &&  bai.initial.install

  case "$swapMode" in
    -lbai) bai.swap.local ;;
    -lbaif) bai.backup; bai.swap.local ;;
    -sbai) bai.swap.stable ;;
    *) [[ -f node_modules/.source && $(cat node_modules/.source) == "local" ]] && bai.swap.local ;;
  esac

  bai.build.run "$@"
}
