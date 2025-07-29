
bai.backup() {
  local target=".trash/node_modules_backup"
  log.info "Backing up installed packages to $target"
  rm -rf "$target"
  mkdir -p "$target"

  for pkg in ts-common commando build-and-install; do
    local from="node_modules/.pnpm/@nu-art+${pkg}@${TS_VERSION}/node_modules/@nu-art/${pkg}"
    cp -R "$from" "$target/$pkg"
  done
}

bai.swap.stable() {
  log.info "Linking stable packages..."
  for pkg in ts-common commando build-and-install; do
    local backup=".trash/node_modules_backup/$pkg"
    local target="node_modules/@nu-art/$pkg"

    rm -rf "$target"
    mkdir -p "$(dirname "$target")"
    ln -s "$(pwd)/$backup" "$target"
  done
  echo "stable" > node_modules/.source
}

bai.swap.local() {
  log.info "Linking local packages from _thunderstorm..."
  for pkg in ts-common commando build-and-install; do
    local src="_thunderstorm/$pkg/dist"
    local dest="node_modules/.pnpm/@nu-art+${pkg}@${TS_VERSION}/node_modules/@nu-art/${pkg}"

    rm -rf "$dest"
    mkdir -p "$dest"
    cp -R "$src/." "$dest"
  done
  echo "local" > node_modules/.source
}
