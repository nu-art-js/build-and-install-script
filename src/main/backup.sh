bai.backup() {
  local target="$REPO_ROOT/.trash/node_modules_backup"

  log.info "Backing up installed pnpm package folders to $target"
  folder.delete "$target"
  folder.create "$target"

  for pkg in ts-common commando build-and-install; do
    local from="node_modules/.pnpm/@nu-art+${pkg}@${TS_VERSION}"
    cp -R "$from" "$target/$pkg"
  done
}

bai.swap.stable() {
  log.info "Restoring stable packages..."

  for pkg in ts-common commando build-and-install; do
    local backup="$REPO_ROOT/.trash/node_modules_backup/$pkg"
    local dest="node_modules/.pnpm/@nu-art+${pkg}@${TS_VERSION}"
    local target="node_modules/@nu-art/$pkg"

    folder.delete "$dest"
    folder.create "$(dirname "$dest")"
    cp -R "$backup" "$dest"

    folder.delete "$target"
    folder.create "$(dirname "$target")"
    symlink.ensure "$(file.path "$dest/node_modules/@nu-art/$pkg")" "$target"
  done

  echo "stable" > node_modules/.source
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

  echo "local" > node_modules/.source
}

