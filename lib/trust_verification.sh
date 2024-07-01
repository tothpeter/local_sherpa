#!/bin/bash

_calculate_checksum() {
  sha256sum .local-sherpa | cut -d ' ' -f 1
}

verify_trust() {
  local checksum_file="$SHERPA_CHECKSUM_DIR/$(pwd | md5sum | cut -d ' ' -f 1)"

  local current_checksum=$(_calculate_checksum)

  # No checksum file?
  if [[ ! -f "$checksum_file" ]]; then
    log_info "The local env file is not trusted. Run \`sherpa trust\` to mark it as trusted."
    return 1
  fi

  local stored_checksum=$(cat "$checksum_file")

  # Did the local env file change?
  if [[ "$current_checksum" != "$stored_checksum" ]]; then
    log_info "The local env file has changed. Run \`sherpa trust\` to mark it trusted."
    return 1
  fi

  # The local env file is trusted
  return 0
}

trust_local_env() {
  if [[ ! -f .local-sherpa ]]; then
    log_info "Nothing to trust. The current directory has no local env file. Run \`sherpa edit\` to create one."
    return 1
  fi

  mkdir -p "$SHERPA_CHECKSUM_DIR"

  local checksum_file="$SHERPA_CHECKSUM_DIR/$(pwd | md5sum | cut -d ' ' -f 1)"
  local current_checksum=$(_calculate_checksum)

  echo "$current_checksum" > "$checksum_file"
  log_info "Trusted!"

  return 0
}

untrust_local_env() {
  local checksum_file="$SHERPA_CHECKSUM_DIR/$(pwd | md5sum | cut -d ' ' -f 1)"

  if [[ -f "$checksum_file" ]]; then
    rm "$checksum_file"
    log_info "Trust revoked!"
  else
    log_info "The local env file was not trusted before."
  fi
}
