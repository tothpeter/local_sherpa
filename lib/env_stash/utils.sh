__SHERPA_ENV_STASH_VAR_PREFIX="__sherpa__env_stash"

# 〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰
#                            Environment Stash Utils
# 〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰

sherpa::env_stash.unstash_all() {
  local -r dir_path="$1"

  sherpa::env_stash.unstash_variables "$dir_path"
  sherpa::env_stash.unstash_aliases "$dir_path"
  sherpa::env_stash.unstash_functions "$dir_path"
}

sherpa::env_stash._item_to_variable_name() {
  local -r item_type="$1"
  local -r dir_path=${2:-$PWD}

  local -r directory_prefix=$(sherpa::env_stash._path_to_variable_prefix "$dir_path")

  echo "${__SHERPA_ENV_STASH_VAR_PREFIX}__${item_type}__${directory_prefix}"
}

sherpa::env_stash._path_to_variable_prefix() {
  local dir_path=${1:-$PWD}
  dir_path="${dir_path:1}" # Remove the first slash
  echo "${dir_path//[^a-zA-Z0-9]/_}"
}
