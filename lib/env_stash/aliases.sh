# 〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰
#                           Stash and unstash aliases
# 〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰

sherpa::env_stash.stash_aliases() {
  local -r dir_path="$1"
  shift
  local -r alias_names=("$@")

  local variable_name_for_aliases_to_restore variable_name_for_aliases_to_remove
  variable_name_for_aliases_to_restore=$(sherpa::env_stash._item_to_variable_name "aliases_to_restore" "$dir_path")
  variable_name_for_aliases_to_remove=$(sherpa::env_stash._item_to_variable_name "aliases_to_remove" "$dir_path")

  local alias_name

  for alias_name in "${alias_names[@]}"; do
    if alias "$alias_name" &> /dev/null; then
      sherpa::env_stash._stash_existing_alias "$alias_name" "$variable_name_for_aliases_to_restore"
    else
      sherpa::env_stash._stash_non_existing_alias "$alias_name" "$variable_name_for_aliases_to_remove"
    fi
  done
}

sherpa::env_stash._stash_existing_alias() {
  local -r alias_name="$1"
  local -r variable_name_for_aliases_to_restore="$2"
  local alias_definition
  alias_definition=$(alias "$alias_name")

  if [ -n "$BASH_VERSION" ]; then
    alias_definition="${alias_definition#alias }" # Remove "alias " prefix
  fi

  # Escape special characters to avoid interpretation at stash time
  alias_definition=$(sherpa::env_stash._escape_for_eval "$alias_definition")

  eval "$variable_name_for_aliases_to_restore+=(\"$alias_definition\")"
}

sherpa::env_stash._stash_non_existing_alias() {
  local -r alias_name="$1"
  local -r variable_name_for_aliases_to_remove="$2"

  eval "$variable_name_for_aliases_to_remove+=(\"$alias_name\")"
}

sherpa::env_stash.unstash_aliases() {
  local -r dir_path="$1"

  sherpa::env_stash._restore_aliases "$dir_path"
  sherpa::env_stash._remove_aliases "$dir_path"
}

sherpa::env_stash._restore_aliases() {
  local -r dir_path="$1"
  local -r variable_name_for_aliases_to_restore=$(sherpa::env_stash._item_to_variable_name "aliases_to_restore" "$dir_path")
  local alias_definition

  if [ -n "$ZSH_VERSION" ]; then
    # shellcheck disable=SC2206,SC2296
    local -r alias_definitions=(${(P)variable_name_for_aliases_to_restore})
  else
    # shellcheck disable=SC2178
    local -rn alias_definitions="$variable_name_for_aliases_to_restore"
  fi

  for alias_definition in "${alias_definitions[@]}"; do
    eval "alias $alias_definition"
  done

  # Clean up
  unset "$variable_name_for_aliases_to_restore"
}

sherpa::env_stash._remove_aliases() {
  local -r dir_path="$1"
  local -r variable_name_for_aliases_to_remove=$(sherpa::env_stash._item_to_variable_name "aliases_to_remove" "$dir_path")
  local alias_name

  if [ -n "$ZSH_VERSION" ]; then
    # shellcheck disable=SC2206,SC2296
    local -r alias_names=(${(P)variable_name_for_aliases_to_remove})
  else
    # shellcheck disable=SC2178
    local -rn alias_names="$variable_name_for_aliases_to_remove"
  fi

  for alias_name in "${alias_names[@]}"; do
    # '2> /dev/null' is used to avoid error messages when an alias does not exist.
    # It happens when an alias is double stashed. There is no protection
    # implemented for this case.
    unalias "$alias_name" 2> /dev/null
  done

  # Clean up
  unset "$variable_name_for_aliases_to_remove"
}
