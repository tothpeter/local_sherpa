# shellcheck disable=SC2317

# Skip if not Bash
[ -z "$BASH_VERSION" ] && echo "Skip: Not Bash"; exit 0

source tests/support/app_helper.sh

stub() {
  local stub_definition=$1=$2

  echo "$stub_definition" >> "$BASHRC"
}

stub_function() {
  local stubbed_function_name=$1
  local replace_function_name=$2

  cat <<EOF >> "$BASHRC"
$stubbed_function_name() {
  $(declare -f "$replace_function_name" | sed '1,2d;$d')
}
EOF
}

reset_stubs() {
  echo "source $SHERPA_LIB_DIR/init.sh" > "$BASHRC"
}

# ==============================================================================
# ++++ Setup

# Sherpa runs the diagnostics with a shell script that would load the
# ~/.bashrc file.
BASHRC=$(mktemp)
cleanup_file_or_dir_at_teardown "$BASHRC"
echo "source $SHERPA_LIB_DIR/init.sh" > "$BASHRC"
BASHRC_FILE="$BASHRC"

STDOUT_FILE=$(mktemp)
cleanup_file_or_dir_at_teardown "$STDOUT_FILE"
STDERR_FILE=$(mktemp)
cleanup_file_or_dir_at_teardown "$STDERR_FILE"

subject() {
  sherpa diagnose 1> "$STDOUT_FILE" 2> "$STDERR_FILE"
}

# ==============================================================================
# ++++ It warns when Sherpa is disabled
sherpa disable

subject

assert_contain "$(cat "$STDERR_FILE")" "Sherpa is disabled!" "It warns when Sherpa is disabled"


# ==============================================================================
# ++++ It acknowledges when Sherpa is enabled
sherpa enable

subject

assert_contain "$(cat "$STDOUT_FILE")" "\[OK\] Enabled" "It acknowledges when Sherpa is enabled"


# ==============================================================================
# ++++ It warns when the sha256sum function is not available
# Stub the type function to simulate a missing sha256sum function
fake_type() {
  if [[ "$1" = "sha256sum" ]]; then
    echo "sha256sum: command not found" >&2
    return 1
  else
    builtin type "\$file_path"
  fi
}
stub_function "type" "fake_type"

subject

assert_contain "$(cat "$STDERR_FILE")" "\[NOT OK\] sha256sum utility" "It warns when the sha256sum function is not available"

reset_stubs


# ==============================================================================
# ++++ It acknowledges when the sha256sum function is available
subject

assert_contain "$(cat "$STDOUT_FILE")" "\[OK\] sha256sum utility" "It acknowledges when the sha256sum function is available"


# ==============================================================================
# ++++ It warns when the cd hook is not setup correctly (the PROMPT_COMMAND got tempered with)
stub "export PROMPT_COMMAND=\"\""

subject

assert_contain "$(cat "$STDERR_FILE")" "\[NOT OK\] cd hook setup" "It warns when the cd hook is not setup correctly"

reset_stubs


# ==============================================================================
# ++++ It acknowledges when the cd hook is setup correctly
subject

assert_contain "$(cat "$STDOUT_FILE")" "\[OK\] cd hook setup" "It acknowledges when the cd hook is setup correctly"


# ==============================================================================
# ++++ It warns when trusting a directory fails
# Stub the sha256sum function to simulate a directory trust failure
fake_sha256sum() {
  echo "sha256sum: command not found" >&2
  exit 1
}
stub_function "sha256sum" "fake_sha256sum"

subject

assert_contain "$(cat "$STDERR_FILE")" "\[NOT OK\] Trusting env files" "It warns when trusting a directory fails"
reset_stubs


# ==============================================================================
# ++++ It acknowledges when trusting a directory succeeds
subject

assert_contain "$(cat "$STDOUT_FILE")" "\[OK\] Trusting env files" "It acknowledges when trusting a directory succeeds"


# ==============================================================================
# ++++ It warns when loading the local env fails
# Stub the source command to simulate a local env loading failure
fake_source() {
  local file_path="$1"

  if [[ "$file_path" = "$SHERPA_ENV_FILENAME" ]]; then
    return 1
  else
    builtin source "$file_path"
  fi
}
stub_function "source" "fake_source"

subject

assert_contain "$(cat "$STDERR_FILE")" "\[NOT OK\] Loading the local environment" "It warns when loading the local env fails"
reset_stubs

# ==============================================================================
# ++++ It acknowledges when loading the local env succeeds
subject

assert_contain "$(cat "$STDOUT_FILE")" "\[OK\] Loading the local environment" "It acknowledges when loading the local env succeeds"
