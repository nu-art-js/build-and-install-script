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
  
  # Ensure certificate directory exists
  folder.create "$cert_dir"
  
  # Ensure certificates exist (lazy generation)
  ssl.ensure_cert "$key_path" "$cert_path" "$days"
  
  # Ensure project SSL directory exists
  folder.create "$project_ssl_dir"
  
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
  
  if [[ "$key_name" == "all" ]]; then
    log.info "Cleaning all SSL certificates from: $cert_dir"
    
    # Remove all certificates from cert directory
    if [[ -d "$cert_dir" ]]; then
      local count
      count=$(find "$cert_dir" -type f \( -name "*.key" -o -name "*.crt" \) | wc -l | tr -d ' ')
      if [[ "$count" -gt 0 ]]; then
        find "$cert_dir" -type f \( -name "*.key" -o -name "*.crt" \) -delete
        log.info "Removed $count certificate file(s) from $cert_dir"
      else
        log.info "No certificate files found in $cert_dir"
      fi
    else
      log.info "Certificate directory does not exist: $cert_dir"
    fi
    
    # Remove all symlinks from project
    if [[ -d "$project_ssl_dir" ]]; then
      local link_count
      link_count=$(find "$project_ssl_dir" -type l | wc -l | tr -d ' ')
      if [[ "$link_count" -gt 0 ]]; then
        find "$project_ssl_dir" -type l -delete
        log.info "Removed $link_count symlink(s) from $project_ssl_dir"
      else
        log.info "No symlinks found in $project_ssl_dir"
      fi
      
      # Remove directory if empty
      if [[ -z "$(ls -A "$project_ssl_dir" 2>/dev/null)" ]]; then
        rmdir "$project_ssl_dir" 2>/dev/null && log.info "Removed empty directory: $project_ssl_dir"
      fi
    else
      log.info "Project SSL directory does not exist: $project_ssl_dir"
    fi
  else
    log.info "Cleaning SSL certificates for: $key_name"
    
    local key_path="${cert_dir}/${key_name}.key"
    local cert_path="${cert_dir}/${key_name}.crt"
    local project_key_link="${project_ssl_dir}/${key_name}.key"
    local project_cert_link="${project_ssl_dir}/${key_name}.crt"
    
    # Remove certificate files
    local removed=0
    if [[ -f "$key_path" ]]; then
      rm -f "$key_path"
      log.info "Removed: $key_path"
      ((removed++))
    fi
    
    if [[ -f "$cert_path" ]]; then
      rm -f "$cert_path"
      log.info "Removed: $cert_path"
      ((removed++))
    fi
    
    if [[ "$removed" -eq 0 ]]; then
      log.info "No certificate files found for: $key_name"
    fi
    
    # Remove symlinks
    local links_removed=0
    if [[ -L "$project_key_link" ]]; then
      rm -f "$project_key_link"
      log.info "Removed symlink: $project_key_link"
      ((links_removed++))
    fi
    
    if [[ -L "$project_cert_link" ]]; then
      rm -f "$project_cert_link"
      log.info "Removed symlink: $project_cert_link"
      ((links_removed++))
    fi
    
    if [[ "$links_removed" -eq 0 ]]; then
      log.info "No symlinks found for: $key_name"
    fi
    
    # Remove directory if empty
    if [[ -d "$project_ssl_dir" ]] && [[ -z "$(ls -A "$project_ssl_dir" 2>/dev/null)" ]]; then
      rmdir "$project_ssl_dir" 2>/dev/null && log.info "Removed empty directory: $project_ssl_dir"
    fi
  fi
  
  log.info "✅ SSL cleanup complete"
}

