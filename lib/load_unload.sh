_sherpa_alert_sherpa_we_changed_dir() {
  # Skip if Sherpa is disabled
  [ "$SHERPA_ENABLED" = false ] && return
  _sherpa_log_debug "Directory changed."
  _sherpa_unload_envs_of_exited_dirs
  _sherpa_load_env_from_current_dir
}

# It unloads the loaded envs of previous directories that we exited
_sherpa_unload_envs_of_exited_dirs() {
  local loaded_paths=()

  for loaded_path in "${SHERPA_LOADED_ENV_DIRS[@]}"; do
    # Keep current and parent directories
    if _sherpa__is_current_or_parent_dir "$loaded_path"; then
      loaded_paths+=("$loaded_path")
    else
      _sherpa_log_debug "Unload env: $loaded_path"

      sherpa::env_stash.unstash_all "$loaded_path"
    fi
  done

  SHERPA_LOADED_ENV_DIRS=("${loaded_paths[@]}")
}

_sherpa__is_current_or_parent_dir() {
  local -r current_dir=$(pwd)
  local -r parent_dir="$1"

  # Does the current path start with the parent path?
  if [[ "$current_dir" == "$parent_dir"* ]]; then
    return 0
  else
    return 1
  fi
}

_sherpa_unload_all_envs() {
  for loaded_path in "${SHERPA_LOADED_ENV_DIRS[@]}"; do
    _sherpa_log_debug "Unload env: $loaded_path"

    sherpa::env_stash.unstash_all "$loaded_path"
  done

  SHERPA_LOADED_ENV_DIRS=()
}

_sherpa_unload_env_of_current_dir() {
  sherpa::env_stash.unstash_all "$PWD"
  _sherpa_utils::array::remove_first_element SHERPA_LOADED_ENV_DIRS
}

_sherpa_load_env_from_current_dir() {
  # Skip if Sherpa is disabled
  [ "$SHERPA_ENABLED" = false ] && return
  _sherpa_log_debug "Load local env?"

  # Skip if there is no local env file
  [ -f "$SHERPA_ENV_FILENAME" ] || { _sherpa_log_debug "No local env file"; return; }

  # Skip if the env was already loaded
  _sherpa_was_env_loaded && { _sherpa_log_debug "Local env is already loaded"; return; }

  # Skip if the local env file is not trusted
  _sherpa_verify_trust || return;

  _sherpa_stash_local_env
  _sherpa_log_debug "Load local env"
  # shellcheck disable=SC1090
  source "$SHERPA_ENV_FILENAME"
  # Append the current directory to the list. This is needed to unload the envs
  # in the right order when we change directories. The root directory should be
  # the last one to unload.
  # shellcheck disable=SC2207
  SHERPA_LOADED_ENV_DIRS=($(pwd) "${SHERPA_LOADED_ENV_DIRS[@]}")
}

_sherpa_was_env_loaded() {
  for loaded_path in "${SHERPA_LOADED_ENV_DIRS[@]}"; do
    if [[ "$loaded_path" == $(pwd) ]]; then
      return 0
    fi
  done

  return 1
}

_sherpa_stash_local_env() {
  _sherpa_log_debug "Stash local env"

  # shellcheck disable=SC2207
  local variable_names=($(_sherpa_fetch_variable_names_from_env_file))
  _sherpa_log_debug "AutoStashing vars: ${variable_names[*]}"
  sherpa::env_stash.stash_variables "$PWD" "${variable_names[@]}"

  # shellcheck disable=SC2207
  local alias_names=($(_sherpa_fetch_aliase_names_from_env_file))
  _sherpa_log_debug "AutoStashing aliases: ${alias_names[*]}"
  sherpa::env_stash.stash_aliases "$PWD" "${alias_names[@]}"

  # shellcheck disable=SC2207
  local function_names=($(_sherpa_fetch_function_names_from_env_file))
  _sherpa_log_debug "AutoStashing functions: ${function_names[*]}"
  sherpa::env_stash.stash_functions "$PWD" "${function_names[@]}"
}

_sherpa_test_local_env_file_for_shell_errors() {
  # shellcheck disable=SC1090
  local -r error_output=$(source "$SHERPA_ENV_FILENAME" 2>&1 >/dev/null)

  if [[ -n "$error_output" ]]; then
    _sherpa_log_error "Error in $SHERPA_ENV_FILENAME" "$error_output"
    return 1
  fi
}
