bai.backup() {
  local label="${1:-default}"
  local target="$REPO_ROOT/.trash/node_modules_backup/$label"

  log.info "Backing up current node_modules to $target"
  folder.delete "$target"
  folder.create "$target"

  for pkg in ts-common commando build-and-install; do
    local from="node_modules/.pnpm/@nu-art+${pkg}@${TS_VERSION}"
    cp -R "$from" "$target/$pkg"
  done
}

bai.restore() {
  local label="${1:-default}"
  local source="$REPO_ROOT/.trash/node_modules_backup/$label"
  log.info "Restoring packages from backup label: $label"

  for pkg in ts-common commando build-and-install; do
    local backup="$source/$pkg"
    local dest="node_modules/.pnpm/@nu-art+${pkg}@${TS_VERSION}"
    local target="node_modules/@nu-art/$pkg"

    folder.delete "$dest"
    folder.create "$(dirname "$dest")"
    cp -R "$backup" "$dest"

    folder.delete "$target"
    folder.create "$(dirname "$target")"
    symlink.ensure "$(file.path "$dest/node_modules/@nu-art/$pkg")" "$target"
  done
}

bai.list.backups() {
  local path="$REPO_ROOT/.trash/node_modules_backup"
  log.info "Available backup labels:"
  find "$path" -maxdepth 1 -mindepth 1 -type d -exec basename {} \; | sort
}

bai.swap.local() {
  log.info "Linking local packages from _thunderstorm..."

  for pkg in ts-common commando build-and-install; do
    local src="_thunderstorm/$pkg/dist"
    local dest="node_modules/.pnpm/@nu-art+${pkg}@${TS_VERSION}/node_modules/@nu-art/${pkg}"

    folder.delete "$dest"
    folder.create "$dest"
    cp -R "$src/." "$dest"
  done
}

