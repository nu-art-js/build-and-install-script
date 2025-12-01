#!/bin/bash

# Note: This file is used within a bundle context where lib.tools is already loaded
# The utilities (folder, symlink, log, error) are provided by lib.tools bundle

## @function: ssl.setup(key_name?, days?)
##
## @description: Ensure SSL certificates exist in ~/.local-dev-cert and create symlinks to .config/.ssl/
##
## @param: $1 - Optional key/cert name (default: localhost)
## @param: $2 - Optional number of days validity (default: 365)
##
## @return: null
ssl.setup() {
  local key_name="${1:-localhost}"
  local days="${2:-365}"
  
  local REPO_ROOT
  REPO_ROOT="$(folder.repo_root)"
  
  # Allow override via environment variable for testing
  local cert_dir="${SSL_CERT_DIR:-${HOME}/.local-dev-cert}"
  local key_path="${cert_dir}/${key_name}.key"
  local cert_path="${cert_dir}/${key_name}.crt"
  
  local project_ssl_dir="${REPO_ROOT}/.config/.ssl"
  local project_key_link="${project_ssl_dir}/${key_name}.key"
  local project_cert_link="${project_ssl_dir}/${key_name}.crt"
  
  log.info "Setting up SSL certificates for: $key_name"
  log.debug "Certificate directory: $cert_dir"
  log.debug "Project SSL directory: $project_ssl_dir"
  
  # Ensure project SSL directory exists
  folder.create "$project_ssl_dir"
  
  # Check if hard files (not symlinks) exist in project workspace and handle them
  if [[ -f "$project_cert_link" ]] && [[ ! -L "$project_cert_link" ]]; then
    log.info "Found hard certificate file in project workspace: $project_cert_link"
    log.info "Untrusting and removing hard files before setting up symlinks"
    
    # Untrust the certificate before deleting
    ssl.untrust_cert "$project_cert_link" || log.warning "Failed to untrust certificate (continuing with deletion)"
    
    # Delete hard files
    rm -f "$project_cert_link" && log.info "Removed hard certificate file: $project_cert_link"
    if [[ -f "$project_key_link" ]] && [[ ! -L "$project_key_link" ]]; then
      rm -f "$project_key_link" && log.info "Removed hard key file: $project_key_link"
    fi
  fi
  
  # Ensure certificate directory exists
  folder.create "$cert_dir"
  
  # Ensure certificates exist (lazy generation)
  ssl.ensure_cert "$key_path" "$cert_path" "$days"
  
  # Trust the certificate
  ssl.trust_cert "$cert_path" || log.warning "Failed to trust certificate automatically"
  
  # Create symlinks
  symlink.ensure "$key_path" "$project_key_link"
  symlink.ensure "$cert_path" "$project_cert_link"
  
  log.info "✅ SSL certificates setup complete"
  log.info "   Key: $project_key_link → $key_path"
  log.info "   Cert: $project_cert_link → $cert_path"
}

## @function: ssl.clean(key_name?, cert_dir?)
##
## @description: Remove SSL certificates and symlinks
##
## @param: $1 - Optional key/cert name (default: localhost). Use "all" to remove all certificates
## @param: $2 - Optional certificate directory (default: ~/.local-dev-cert)
##
## @return: null
ssl.clean() {
  local key_name="${1:-localhost}"
  # Allow override via environment variable for testing, or use provided parameter
  local cert_dir="${2:-${SSL_CERT_DIR:-${HOME}/.local-dev-cert}}"
  
  local REPO_ROOT
  REPO_ROOT="$(folder.repo_root)"
  
  local project_ssl_dir="${REPO_ROOT}/.config/.ssl"
  
  # Determine which keys to delete
  local keys_to_delete=()
  
  if [[ "$key_name" == "all" ]]; then
    log.info "Cleaning all SSL certificates from: $cert_dir"
    
    # Find all .key files and extract their base names
    if [[ -d "$cert_dir" ]]; then
      while IFS= read -r key_file; do
        local basename
        basename="$(basename "$key_file" .key)"
        keys_to_delete+=("$basename")
      done < <(find "$cert_dir" -maxdepth 1 -type f -name "*.key" 2>/dev/null)
    fi
    
    if [[ ${#keys_to_delete[@]} -eq 0 ]]; then
      log.info "No certificate files found in $cert_dir"
    fi
  else
    log.info "Cleaning SSL certificates for: $key_name"
    keys_to_delete=("$key_name")
  fi
  
  # Iterate over keys and delete certificates and symlinks
  local total_removed=0
  local total_links_removed=0
  
  # Inner function to remove a file and its symlink (updates parent scope counters)
  remove_file_and_symlink() {
    local file_path="$1"
    local symlink_path="$2"
    
    # Remove certificate file
    if [[ -f "$file_path" ]]; then
      rm -f "$file_path" && log.info "Removed: $file_path" || log.warning "Failed to remove: $file_path"
      total_removed=$((total_removed + 1))
    fi
    
    # Remove symlink (check for symlinks, including broken ones)
    if [[ -L "$symlink_path" ]] || [[ -e "$symlink_path" ]]; then
      if rm -f "$symlink_path" 2>/dev/null; then
        log.info "Removed symlink: $symlink_path"
        total_links_removed=$((total_links_removed + 1))
      else
        log.warning "Failed to remove symlink: $symlink_path"
      fi
    fi
  }
  
  for key in "${keys_to_delete[@]}"; do
    local key_path="${cert_dir}/${key}.key"
    local cert_path="${cert_dir}/${key}.crt"
    local project_key_link="${project_ssl_dir}/${key}.key"
    local project_cert_link="${project_ssl_dir}/${key}.crt"
    
    # If certificate file exists in project workspace, untrust it before deletion
    if [[ -e "$project_cert_link" ]] && [[ -f "$cert_path" ]]; then
      log.info "Untrusting certificate before deletion: $cert_path"
      ssl.untrust_cert "$cert_path" || log.warning "Failed to untrust certificate (continuing with deletion)"
    fi
    
    # Remove key file and its symlink
    remove_file_and_symlink "$key_path" "$project_key_link"
    
    # Remove cert file and its symlink
    remove_file_and_symlink "$cert_path" "$project_cert_link"
  done
  
  # Summary logging
  if [[ ${#keys_to_delete[@]} -gt 0 ]]; then
    if [[ $total_removed -eq 0 ]]; then
      log.info "No certificate files found for the specified key(s)"
    fi
    if [[ $total_links_removed -eq 0 ]]; then
      log.info "No symlinks found for the specified key(s)"
    fi
  fi
  
  # Remove directories if empty
  if [[ -d "$project_ssl_dir" ]] && [[ -z "$(ls -A "$project_ssl_dir" 2>/dev/null)" ]]; then
    rmdir "$project_ssl_dir" 2>/dev/null && log.info "Removed empty directory: $project_ssl_dir"
  fi
  
  # Remove parent .config directory if it becomes empty (independent check)
  local config_dir="${REPO_ROOT}/.config"
  if [[ -d "$config_dir" ]] && [[ -z "$(ls -A "$config_dir" 2>/dev/null)" ]]; then
    rmdir "$config_dir" 2>/dev/null && log.info "Removed empty directory: $config_dir"
  fi
  
  log.info "✅ SSL cleanup complete"
}

