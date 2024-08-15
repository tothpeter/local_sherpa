# shellcheck disable=SC2155
readonly TMP_TEST_DIR=$(mktemp -d)
# shellcheck disable=SC2155
readonly STDERR_FILE=$(mktemp)

trap teardown EXIT
teardown() {
  rm -r "$TMP_TEST_DIR"
  rm "$STDERR_FILE"
}

print_success() {
  local message=$1
  printf "\e[32m%s\e[0m\n" "$message"
}

print_error() {
  local message=$1
  printf "\e[31m%s\e[0m\n" "$message" >&2
}

check_local_env_file() {
  _check_local_env_file_exists &&
    _check_local_env_file_readable &&
    _check_local_env_file_has_no_shell_errors &&
    _check_local_env_file_trusted &&
    print_success "[OK] Local $SHERPA_ENV_FILENAME file"
}

_check_local_env_file_exists() {
  if [ ! -f "$SHERPA_ENV_FILENAME" ]; then
    print "There is no local $SHERPA_ENV_FILENAME file. Skipping local tests."
    return 1
  fi
}

_check_local_env_file_readable() {
  if ! cat "$SHERPA_ENV_FILENAME" >/dev/null 2>&1; then
    print_error "[NOT OK] Local $SHERPA_ENV_FILENAME file"
    echo "Cannot read the file." >&2
    return 1
  fi
}

_check_local_env_file_has_no_shell_errors() {
  # shellcheck disable=SC1090
  local -r error_output=$(source "$SHERPA_ENV_FILENAME" 2>&1 >/dev/null)

  if [[ -n "$error_output" ]]; then
    print_error "[NOT OK] Local $SHERPA_ENV_FILENAME file"
    echo "$error_output" >&2
    return 1
  fi
}

_check_local_env_file_trusted() {
  local -r current_log_level=$SHERPA_LOG_LEVEL
  SHERPA_LOG_LEVEL=$SHERPA_LOG_LEVEL_WARN
  local -r output=$(_sherpa_verify_trust 2>&1)
  SHERPA_LOG_LEVEL=$current_log_level

  if [[ -n "$output" ]]; then
    print_error "[NOT OK] Local $SHERPA_ENV_FILENAME file"
    echo "$output" >&2
    return 1
  fi
}


check_enabled() {
  if [ "$SHERPA_ENABLED" = true ]; then
    print_success "[OK] Enabled"
  else
    print_error "[NOT OK] Enabled"
    echo "Sherpa is disabled! Enable it with 'sherpa on'." >&2
    exit 1
  fi
}

check_checksum_function_exists() {
  if type sha256sum > /dev/null 2>&1; then
    print_success "[OK] sha256sum utility"
  else
    print_error "[NOT OK] sha256sum utility"
    echo "Make sure the sha256sum utility is available in your system." >&2
    exit 1
  fi
}

setup_test_dir() {
  export SHERPA_CHECKSUM_DIR="$TMP_TEST_DIR/checksums"

  cd "$TMP_TEST_DIR"
  echo "alias test_alias_1=\"echo works\"" > "$SHERPA_ENV_FILENAME"
}

test_trusting_the_current_directory() {
  if sherpa trust > /dev/null 2> "$STDERR_FILE"; then
    print_success "[OK] Trusting env files"
  else
    print_error "[NOT OK] Trusting env files"
    cat "$STDERR_FILE" >&2
    rm "$STDERR_FILE"
    exit 1
  fi
}

test_loading_the_local_env() {
  if [ "$(test_alias_1 2> /dev/null)" = "works" ]; then
    print_success "[OK] Loading the local environment"
  else
    print_error "[NOT OK] Loading the local environment"
    exit 1
  fi
}

print_all_ok() {
  echo ""
  print_success "All systems are up and operational."
}
