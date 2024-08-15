# 〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰
#                           Stash and unstash variables
# 〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰

sherpa::env_stash.stash_variables() {
  local -r dir_path="$1"
  shift
  local -r variable_names=("$@")

  local variable_name_for_variables_to_restore variable_name_for_variables_to_remove
  variable_name_for_variables_to_restore=$(sherpa::env_stash._item_to_variable_name "variables_to_restore" "$dir_path")
  variable_name_for_variables_to_remove=$(sherpa::env_stash._item_to_variable_name "variables_to_remove" "$dir_path")

  local variable_name

  for variable_name in "${variable_names[@]}"; do
    if declare -p "$variable_name" &> /dev/null; then
      sherpa::env_stash._stash_existing_variable "$variable_name" "$variable_name_for_variables_to_restore"
    else
      sherpa::env_stash._stash_non_existing_variable "$variable_name" "$variable_name_for_variables_to_remove"
    fi
  done
}

sherpa::env_stash._stash_existing_variable() {
  local -r variable_name="$1"
  local -r variable_name_for_variables_to_restore="$2"
  local variable_definition
  variable_definition=$(declare -p "$variable_name")

  # Escape special characters to avoid interpretation at stash time
  variable_definition=$(sherpa::env_stash._escape_for_eval "$variable_definition")

  eval "$variable_name_for_variables_to_restore+=(\"$variable_definition\")"
}

sherpa::env_stash._stash_non_existing_variable() {
  local -r variable_name="$1"
  local -r variable_name_for_variables_to_remove="$2"

  eval "$variable_name_for_variables_to_remove+=(\"$variable_name\")"
}

sherpa::env_stash.unstash_variables() {
  local -r dir_path="$1"

  sherpa::env_stash._restore_variables "$dir_path"
  sherpa::env_stash._remove_variables "$dir_path"
}

sherpa::env_stash._restore_variables() {
  local -r dir_path="$1"
  local -r variable_name_for_variables_to_restore=$(sherpa::env_stash._item_to_variable_name "variables_to_restore" "$dir_path")
  local variable_definition

  if [ -n "$ZSH_VERSION" ]; then
    # shellcheck disable=SC2206,SC2296
    local -r variable_definitions=(${(P)variable_name_for_variables_to_restore})
  else
    # shellcheck disable=SC2178
    local -rn variable_definitions="$variable_name_for_variables_to_restore"
  fi

  for variable_definition in "${variable_definitions[@]}"; do
    # Add -g to make the variable global so it won't be limited to the current
    # function scope.
    eval "${variable_definition/declare /declare -g }"
  done

  # Clean up
  unset "$variable_name_for_variables_to_restore"
}

sherpa::env_stash._remove_variables() {
  local -r dir_path="$1"
  local -r variable_name_for_variables_to_remove=$(sherpa::env_stash._item_to_variable_name "variables_to_remove" "$dir_path")
  local variable_name

  if [ -n "$ZSH_VERSION" ]; then
    # shellcheck disable=SC2206,SC2296
    local -r variable_names=(${(P)variable_name_for_variables_to_remove})
  else
    # shellcheck disable=SC2178
    local -rn variable_names="$variable_name_for_variables_to_remove"
  fi

  for variable_name in "${variable_names[@]}"; do
    # '2> /dev/null' is used to avoid error messages when an variable does not exist.
    # It happens when an variable is double stashed. There is no protection
    # implemented for this case.
    unset "$variable_name" 2> /dev/null
  done

  # Clean up
  unset "$variable_name_for_variables_to_remove"
}
