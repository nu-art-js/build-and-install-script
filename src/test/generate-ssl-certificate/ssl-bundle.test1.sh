#!/bin/bash

## Test Suite: ssl-bundle.test.sh
## Description: Validates SSL bundle functionality (generate, clean, symlinks)

# Import bash-tools utilities
import "${MAIN_SOURCE_FOLDER}/file-system/folder.sh"
import "${MAIN_SOURCE_FOLDER}/file-system/symlink.sh"
import "${MAIN_SOURCE_FOLDER}/bash-it/expect.sh"
import "${MAIN_SOURCE_FOLDER}/core/logger.sh"
import "${MAIN_SOURCE_FOLDER}/ssl/ssl.sh"

# Import bundle files
BUNDLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../main/generate-ssl-certificate"
import "${BUNDLE_DIR}/ssl-utils.sh"
import "${BUNDLE_DIR}/ssl.sh"
import "${BUNDLE_DIR}/cli.sh"

before_each() {
  # Use temporary directories - ALL files must be under this directory
  TMP_SSL_TEST_DIR="${TEST_DIST_FOLDER:-/tmp}/.tmp-ssl-bundle-test-$$"
  TMP_CERT_DIR="${TMP_SSL_TEST_DIR}/certs"
  TMP_REPO_DIR="${TMP_SSL_TEST_DIR}/repo"
  
  # Create directory structure
  mkdir -p "$TMP_CERT_DIR"
  mkdir -p "$TMP_REPO_DIR/.config"
  
  # Create a mock repo root with .git directory
  cd "$TMP_REPO_DIR" || exit 1
  git init >/dev/null 2>&1 || true
  
  # Set SSL_CERT_DIR environment variable to use test directory
  # This prevents tests from touching ~/.local-dev-cert
  export SSL_CERT_DIR="$TMP_CERT_DIR"
  
  # Store original working directory
  export ORIG_PWD="$(pwd)"
  
  # Override folder.repo_root to return our test repo
  # This ensures symlinks are created in the test repo, not the actual repo
  folder.repo_root() {
    echo "$TMP_REPO_DIR"
  }
  
  # Clean up any existing files
  rm -f "$TMP_CERT_DIR"/*.key "$TMP_CERT_DIR"/*.crt 2>/dev/null
  rm -f "$TMP_REPO_DIR/.config/.ssl"/*.key "$TMP_REPO_DIR/.config/.ssl"/*.crt 2>/dev/null
  rm -rf "$TMP_REPO_DIR/.config/.ssl" 2>/dev/null
  
  # Change to test repo directory so folder.repo_root() finds it
  cd "$TMP_REPO_DIR" || exit 1
}

after_each() {
  # Verify no files were created outside the test directory
  # This is a safety check to ensure tests don't pollute the system
  if [[ -n "$TMP_SSL_TEST_DIR" ]] && [[ -d "$TMP_SSL_TEST_DIR" ]]; then
    # Check that no files exist outside our temp directory
    # (This is a sanity check - if something went wrong, we'll know)
    local files_outside
    files_outside=$(find "$TMP_SSL_TEST_DIR/.." -maxdepth 1 -name ".tmp-ssl-bundle-test-*" ! -path "$TMP_SSL_TEST_DIR" 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$files_outside" -gt 0 ]]; then
      log.warning "Found test files outside expected directory - this should not happen"
    fi
  fi
  
  # Unset SSL_CERT_DIR to restore default behavior
  unset SSL_CERT_DIR
  
  # Restore original directory
  cd "${ORIG_PWD:-/tmp}" 2>/dev/null || cd /tmp
  
  # Clean up entire test directory tree
  if [[ -n "$TMP_SSL_TEST_DIR" ]] && [[ -d "$TMP_SSL_TEST_DIR" ]]; then
    rm -rf "$TMP_SSL_TEST_DIR"
  fi
}

test_ssl_generate_creates_certificates() {
  local key_name="test-localhost"
  
  # SSL_CERT_DIR is set in before_each, so certificates will go to test directory
  local cert_dir="${SSL_CERT_DIR}"
  
  # Call generate (which calls setup)
  ssl.generate "$key_name" 365
  
  # Verify certificates were created
  expect.run "[[ -f \"$cert_dir/${key_name}.key\" ]]" to.return 0
  expect.run "[[ -f \"$cert_dir/${key_name}.crt\" ]]" to.return 0
}

test_ssl_generate_creates_symlinks() {
  local key_name="test-localhost"
  local cert_dir="${SSL_CERT_DIR}"
  
  ssl.generate "$key_name" 365
  
  # Verify symlinks were created in project
  local project_ssl_dir="${TMP_REPO_DIR}/.config/.ssl"
  expect.run "[[ -L \"$project_ssl_dir/${key_name}.key\" ]]" to.return 0
  expect.run "[[ -L \"$project_ssl_dir/${key_name}.crt\" ]]" to.return 0
  
  # Verify symlinks point to correct locations
  local key_target cert_target
  key_target="$(readlink "$project_ssl_dir/${key_name}.key")"
  cert_target="$(readlink "$project_ssl_dir/${key_name}.crt")"
  
  expect "$key_target" to.equal "$cert_dir/${key_name}.key"
  expect "$cert_target" to.equal "$cert_dir/${key_name}.crt"
}

test_ssl_generate_is_idempotent() {
  local key_name="test-localhost"
  local cert_dir="${SSL_CERT_DIR}"
  
  # Generate first time
  ssl.generate "$key_name" 365
  local first_key_hash first_cert_hash
  first_key_hash="$(md5sum "$cert_dir/${key_name}.key" 2>/dev/null | cut -d' ' -f1 || md5 -q "$cert_dir/${key_name}.key" 2>/dev/null)"
  first_cert_hash="$(md5sum "$cert_dir/${key_name}.crt" 2>/dev/null | cut -d' ' -f1 || md5 -q "$cert_dir/${key_name}.crt" 2>/dev/null)"
  
  # Generate again (should not regenerate)
  ssl.generate "$key_name" 365
  
  local second_key_hash second_cert_hash
  second_key_hash="$(md5sum "$cert_dir/${key_name}.key" 2>/dev/null | cut -d' ' -f1 || md5 -q "$cert_dir/${key_name}.key" 2>/dev/null)"
  second_cert_hash="$(md5sum "$cert_dir/${key_name}.crt" 2>/dev/null | cut -d' ' -f1 || md5 -q "$cert_dir/${key_name}.crt" 2>/dev/null)"
  
  expect "$first_key_hash" to.equal "$second_key_hash"
  expect "$first_cert_hash" to.equal "$second_cert_hash"
}

test_ssl_clean_removes_specific_certificate() {
  local key_name="test-localhost"
  local cert_dir="${SSL_CERT_DIR}"
  
  # Generate first
  ssl.generate "$key_name" 365
  
  # Verify files exist
  expect.run "[[ -f \"$cert_dir/${key_name}.key\" ]]" to.return 0
  expect.run "[[ -f \"$cert_dir/${key_name}.crt\" ]]" to.return 0
  
  # Clean
  ssl.clean "$key_name" "$cert_dir"
  
  # Verify files are removed
  expect.run "[[ ! -f \"$cert_dir/${key_name}.key\" ]]" to.return 0
  expect.run "[[ ! -f \"$cert_dir/${key_name}.crt\" ]]" to.return 0
}

test_ssl_clean_removes_symlinks() {
  local key_name="test-localhost"
  local cert_dir="${SSL_CERT_DIR}"
  
  # Generate first
  ssl.generate "$key_name" 365
  
  local project_ssl_dir="${TMP_REPO_DIR}/.config/.ssl"
  expect.run "[[ -L \"$project_ssl_dir/${key_name}.key\" ]]" to.return 0
  expect.run "[[ -L \"$project_ssl_dir/${key_name}.crt\" ]]" to.return 0
  
  # Clean
  ssl.clean "$key_name" "$cert_dir"
  
  # Verify symlinks are removed
  expect.run "[[ ! -L \"$project_ssl_dir/${key_name}.key\" ]]" to.return 0
  expect.run "[[ ! -L \"$project_ssl_dir/${key_name}.crt\" ]]" to.return 0
}

test_ssl_clean_removes_empty_directory() {
  local key_name="test-localhost"
  local cert_dir="${SSL_CERT_DIR}"
  
  # Generate first
  ssl.generate "$key_name" 365
  
  local project_ssl_dir="${TMP_REPO_DIR}/.config/.ssl"
  expect.run "[[ -d \"$project_ssl_dir\" ]]" to.return 0
  
  # Clean
  ssl.clean "$key_name" "$cert_dir"
  
  # Verify directory is removed if empty
  expect.run "[[ ! -d \"$project_ssl_dir\" ]]" to.return 0
}

test_ssl_clean_all_removes_all_certificates() {
  local cert_dir="${SSL_CERT_DIR}"
  
  # Generate multiple certificates
  ssl.generate "cert1" 365
  ssl.generate "cert2" 365
  ssl.generate "cert3" 365
  
  # Verify they exist
  expect.run "[[ -f \"$cert_dir/cert1.key\" ]]" to.return 0
  expect.run "[[ -f \"$cert_dir/cert2.key\" ]]" to.return 0
  expect.run "[[ -f \"$cert_dir/cert3.key\" ]]" to.return 0
  
  # Clean all
  ssl.clean "all" "$cert_dir"
  
  # Verify all are removed
  expect.run "[[ ! -f \"$cert_dir/cert1.key\" ]]" to.return 0
  expect.run "[[ ! -f \"$cert_dir/cert2.key\" ]]" to.return 0
  expect.run "[[ ! -f \"$cert_dir/cert3.key\" ]]" to.return 0
  expect.run "[[ ! -f \"$cert_dir/cert1.crt\" ]]" to.return 0
  expect.run "[[ ! -f \"$cert_dir/cert2.crt\" ]]" to.return 0
  expect.run "[[ ! -f \"$cert_dir/cert3.crt\" ]]" to.return 0
}

test_ssl_clean_all_removes_all_symlinks() {
  local cert_dir="${SSL_CERT_DIR}"
  
  # Generate multiple certificates
  ssl.generate "cert1" 365
  ssl.generate "cert2" 365
  
  local project_ssl_dir="${TMP_REPO_DIR}/.config/.ssl"
  expect.run "[[ -L \"$project_ssl_dir/cert1.key\" ]]" to.return 0
  expect.run "[[ -L \"$project_ssl_dir/cert2.key\" ]]" to.return 0
  
  # Clean all
  ssl.clean "all" "$cert_dir"
  
  # Verify all symlinks are removed
  local link_count
  link_count=$(find "$project_ssl_dir" -type l 2>/dev/null | wc -l | tr -d ' ')
  expect "$link_count" to.equal "0"
}

test_ssl_clean_handles_missing_files_gracefully() {
  local key_name="nonexistent"
  local cert_dir="${SSL_CERT_DIR}"
  
  # Clean non-existent certificate (should not fail)
  expect.run "ssl.clean \"$key_name\" \"$cert_dir\"" to.return 0
}

test_ssl_clean_handles_missing_symlinks_gracefully() {
  local key_name="test-localhost"
  local cert_dir="${SSL_CERT_DIR}"
  
  # Create cert files but no symlinks
  ssl.generate_cert "$cert_dir/${key_name}.key" "$cert_dir/${key_name}.crt" 365
  
  # Clean should not fail even if symlinks don't exist
  expect.run "ssl.clean \"$key_name\" \"$cert_dir\"" to.return 0
}

test_ssl_all_files_created_under_temp_directory() {
  # This test verifies that ALL generated files are under TMP_SSL_TEST_DIR
  # and nothing leaks outside to the actual system
  
  local key_name="test-isolation"
  local cert_dir="${SSL_CERT_DIR}"
  
  # Generate certificates
  ssl.generate "$key_name" 365
  
  # Verify all files are under the temp test directory
  local cert_dir_abs repo_dir_abs temp_dir_abs
  cert_dir_abs="$(cd "$cert_dir" && pwd)"
  repo_dir_abs="$(cd "$TMP_REPO_DIR" && pwd)"
  temp_dir_abs="$(cd "$TMP_SSL_TEST_DIR" && pwd)"
  
  # Certificates should be under temp directory (check if cert_dir starts with temp_dir)
  local cert_in_temp repo_in_temp
  if [[ "$cert_dir_abs" == "$temp_dir_abs"* ]] || [[ "$cert_dir_abs" == "$temp_dir_abs" ]]; then
    cert_in_temp="yes"
  else
    cert_in_temp="no"
  fi
  
  if [[ "$repo_dir_abs" == "$temp_dir_abs"* ]] || [[ "$repo_dir_abs" == "$temp_dir_abs" ]]; then
    repo_in_temp="yes"
  else
    repo_in_temp="no"
  fi
  
  expect "$cert_in_temp" to.equal "yes"
  expect "$repo_in_temp" to.equal "yes"
  
  # Verify certificate files exist and are in temp directory
  expect.run "[[ -f \"$cert_dir/${key_name}.key\" ]]" to.return 0
  expect.run "[[ -f \"$cert_dir/${key_name}.crt\" ]]" to.return 0
  
  # Verify symlinks are in temp repo directory
  local project_ssl_dir="${TMP_REPO_DIR}/.config/.ssl"
  expect.run "[[ -L \"$project_ssl_dir/${key_name}.key\" ]]" to.return 0
  expect.run "[[ -L \"$project_ssl_dir/${key_name}.crt\" ]]" to.return 0
  
  # Verify symlink targets are also in temp directory
  local key_target cert_target
  key_target="$(readlink -f "$project_ssl_dir/${key_name}.key" 2>/dev/null || readlink "$project_ssl_dir/${key_name}.key")"
  cert_target="$(readlink -f "$project_ssl_dir/${key_name}.crt" 2>/dev/null || readlink "$project_ssl_dir/${key_name}.crt")"
  
  # Both targets should be under temp directory
  # Use string prefix check: if target starts with temp_dir, it's contained
  local key_in_temp cert_in_temp
  if [[ "$key_target" == "$temp_dir_abs"* ]] || [[ "$key_target" == "$temp_dir_abs" ]]; then
    key_in_temp="yes"
  else
    key_in_temp="no"
  fi
  
  if [[ "$cert_target" == "$temp_dir_abs"* ]] || [[ "$cert_target" == "$temp_dir_abs" ]]; then
    cert_in_temp="yes"
  else
    cert_in_temp="no"
  fi
  
  expect "$key_in_temp" to.equal "yes"
  expect "$cert_in_temp" to.equal "yes"
  
  # Verify nothing was created in the actual HOME directory (if different from temp)
  local home_cert_dir="${HOME}/.local-dev-cert"
  if [[ "$home_cert_dir" != "$temp_dir_abs"* ]] && [[ "$home_cert_dir" != "$temp_dir_abs" ]]; then
    expect.run "[[ ! -f \"${home_cert_dir}/${key_name}.key\" ]]" to.return 0
    expect.run "[[ ! -f \"${home_cert_dir}/${key_name}.crt\" ]]" to.return 0
  fi
}

