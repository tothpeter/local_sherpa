# 〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰
#                           Stash and unstash aliases
# 〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰

sherpa::env_stash.stash_aliases() {
  local -r dir_path="$1"
  shift
  local -r alias_names=("$@")

  local variable_name_for_aliases_to_remove variable_name_for_aliases_to_restore
  variable_name_for_aliases_to_remove=$(sherpa::env_stash._item_to_variable_name "aliases_to_remove" "$dir_path")
  variable_name_for_aliases_to_restore=$(sherpa::env_stash._item_to_variable_name "aliases_to_restore" "$dir_path")

  local alias_name alias_definition alias_definition_long

  for alias_name in "${alias_names[@]}"; do
    # Stash non existing alias
    if ! alias "$alias_name" &> /dev/null; then
      eval "$variable_name_for_aliases_to_remove+=(\"$alias_name\")"
      continue
    fi

    # Stash existing alias
    if [ -n "$ZSH_VERSION" ]; then
      alias_definition=$(alias "$alias_name")
    else
      alias_definition_long=$(alias "$alias_name")
      alias_definition="${alias_definition_long#alias }" # Remove "alias " prefix
    fi

    # Escape special characters to avoid interpretation at stash time
    alias_definition="${alias_definition//\\/\\\\}"
    alias_definition="${alias_definition//\"/\\\"}"
    alias_definition="${alias_definition//\`/\\\`}"
    alias_definition="${alias_definition//\$/\\\$}"

    eval "$variable_name_for_aliases_to_restore+=(\"$alias_definition\")"
  done
}

sherpa::env_stash.unstash_aliases() {
  local -r dir_path=${1:-$PWD}

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