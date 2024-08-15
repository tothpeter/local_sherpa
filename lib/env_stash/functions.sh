# 〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰
#                           Stash and unstash functions
# 〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰

sherpa::env_stash.stash_functions() {
  local -r dir_path="$1"
  shift
  local -r function_names=("$@")

  local variable_name_for_functions_to_restore variable_name_for_functions_to_remove
  variable_name_for_functions_to_restore=$(sherpa::env_stash._item_to_variable_name "functions_to_restore" "$dir_path")
  variable_name_for_functions_to_remove=$(sherpa::env_stash._item_to_variable_name "functions_to_remove" "$dir_path")

  local function_name

  for function_name in "${function_names[@]}"; do
    if type "$function_name" &> /dev/null; then
      sherpa::env_stash._stash_existing_function "$function_name" "$variable_name_for_functions_to_restore"
    else
      sherpa::env_stash._stash_non_existing_function "$function_name" "$variable_name_for_functions_to_remove"
    fi
  done
}

sherpa::env_stash._stash_existing_function() {
  local -r function_name="$1"
  local -r variable_name_for_functions_to_restore="$2"
  local function_definition
  function_definition=$(declare -f "$function_name")

  # Escape special characters to avoid interpretation at stash time
  function_definition=$(sherpa::env_stash._escape_for_eval "$function_definition")

  eval "$variable_name_for_functions_to_restore+=(\"$function_definition\")"
}

sherpa::env_stash._stash_non_existing_function() {
  local -r function_name="$1"
  local -r variable_name_for_functions_to_remove="$2"

  eval "$variable_name_for_functions_to_remove+=(\"$function_name\")"
}

sherpa::env_stash.unstash_functions() {
  local -r dir_path="$1"

  sherpa::env_stash._restore_functions "$dir_path"
  sherpa::env_stash._remove_functions "$dir_path"
}

sherpa::env_stash._restore_functions() {
  local -r dir_path="$1"
  local -r variable_name_for_functions_to_restore=$(sherpa::env_stash._item_to_variable_name "functions_to_restore" "$dir_path")
  local function_definition

  if [ -n "$ZSH_VERSION" ]; then
    # shellcheck disable=SC2206,SC2296
    local -r function_definitions=(${(P)variable_name_for_functions_to_restore})
  else
    # shellcheck disable=SC2178
    local -rn function_definitions="$variable_name_for_functions_to_restore"
  fi

  for function_definition in "${function_definitions[@]}"; do
    eval "$function_definition"
  done

  # Clean up
  unset "$variable_name_for_functions_to_restore"
}

sherpa::env_stash._remove_functions() {
  local -r dir_path="$1"
  local -r variable_name_for_functions_to_remove=$(sherpa::env_stash._item_to_variable_name "functions_to_remove" "$dir_path")
  local function_name

  if [ -n "$ZSH_VERSION" ]; then
    # shellcheck disable=SC2206,SC2296
    local -r function_names=(${(P)variable_name_for_functions_to_remove})
  else
    # shellcheck disable=SC2178
    local -rn function_names="$variable_name_for_functions_to_remove"
  fi

  for function_name in "${function_names[@]}"; do
    # '2> /dev/null' is used to avoid error messages when an function does not exist.
    # It happens when an function is double stashed. There is no protection
    # implemented for this case.
    unset -f "$function_name" 2> /dev/null
  done

  # Clean up
  unset "$variable_name_for_functions_to_remove"
}
