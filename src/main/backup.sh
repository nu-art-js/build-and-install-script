#!/bin/bash

BACKUP_DIR="$(pwd)/.trash/node_modules_backup"

backup.modules() {
  folder.delete "$BACKUP_DIR"
  folder.create "$BACKUP_DIR"

  for pkg in ts-common commando build-and-install; do
    backup.pnpm_package "$pkg"
  done
}

backup.pnpm_package() {
  local name="$1"
  local from="$NODE_MODULES_DIR/.pnpm/@nu-art+${name}@${TS_VERSION}/node_modules/@nu-art/${name}"
  local to="$BACKUP_DIR/${name}"

  log.info "Backing up $name -> $to"
  cp -R "$from" "$to"
}

copy.backup() {
  local from="$1"
  local to="$2"
  local name="$3"

  log.info "Copying $name from $from to $to"
  [[ ! -d "$to" ]] && mkdir -p "$to"
  rm -rf "${to:?}"/* "${to:?}"/.[!.]* "${to:?}"/.??*
  cp -R "$from/." "$to"
}


