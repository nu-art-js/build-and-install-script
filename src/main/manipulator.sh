#!/bin/bash

set.stable_package() {
  local name="$1"
  local from="$BACKUP_DIR/$name"
  local to="$NODE_MODULES_DIR/@nu-art/$name"

  if [[ -L "$to" ]]; then
    local targetPath="$(readlink "$to")"

    if [[ ! -d "$targetPath" ]]; then
      log.warning "Target does not exist. Recreating and relinking..."
      rm -f "$to"
      mkdir -p "$from"
      ln -s "$from" "$to"
    fi
  else
    rm -rf "$to"
    mkdir -p "$from"
    ln -s "$from" "$to"
  fi

  copy.backup "$from" "$to" "$name"
}

set.local_package() {
  local name="$1"
  local folderName="$2"

  local from="$(pwd)/_thunderstorm/${folderName}/dist"
  local to="$NODE_MODULES_DIR/.pnpm/@nu-art+${name}@${TS_VERSION}/node_modules/@nu-art/${name}"

  copy.backup "$from" "$to" "$name"
}

manipulate.build() {
  case "$1" in
    -sbai)
      for pkg in ts-common commando build-and-install; do
        set.stable_package "$pkg"
      done
      echo "stable" > "$NODE_MODULES_DIR/.source"
      ;;
    -lbai)
      backup.modules
      for pkg in ts-common commando build-and-install; do
        set.local_package "$pkg" "$pkg"
      done
      ;;
    -lbaif)
      for pkg in ts-common commando build-and-install; do
        set.local_package "$pkg" "$pkg"
      done
      echo "local" > "$NODE_MODULES_DIR/.source"
      ;;
  esac
}


