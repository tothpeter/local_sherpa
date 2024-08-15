_sherpa_fetch_variable_names_from_env_file() {
  __load_dynamic() {
    local -Ar VAR_NAMES_TO_IGNORE=(
      [__sherpa_tmp_var_name]=''
      [__vars_after]=''
      [__vars_before]=''

      [functions_source]=''
      [RANDOM]=''
      [LINENO]=''
      [BASH_COMMAND]=''
      [EPOCHREALTIME]=''
      [SRANDOM]=''
      [modules]=''
      [LOGCHECK]=''
      [zle_bracketed_paste]=''
      [parameters]=''
      [WATCHFMT]=''
    )
    local -A __vars_before
    local -A __vars_after
    local __sherpa_tmp_var_name

    # == Get a snapshot of the variables before sourcing the local env file
    if [ -n "$ZSH_VERSION" ]; then
      for __sherpa_tmp_var_name in $(compgen -v); do
        # shellcheck disable=SC2296
        __vars_before[$__sherpa_tmp_var_name]="${(P)__sherpa_tmp_var_name}"
      done
    else
      for __sherpa_tmp_var_name in $(compgen -v); do
        __vars_before[$__sherpa_tmp_var_name]="${!__sherpa_tmp_var_name}"
      done
    fi

    # shellcheck disable=SC1090
    source "$SHERPA_ENV_FILENAME"

    # == Get a snapshot of the variables after sourcing the local env file
    if [ -n "$ZSH_VERSION" ]; then
      for __sherpa_tmp_var_name in $(compgen -v); do
        # shellcheck disable=SC2296
        __vars_after[$__sherpa_tmp_var_name]="${(P)__sherpa_tmp_var_name}"
      done
    else
      for __sherpa_tmp_var_name in $(compgen -v); do
        __vars_after[$__sherpa_tmp_var_name]="${!__sherpa_tmp_var_name}"
      done
    fi

    # == Return new and changed variables
    if [ -n "$ZSH_VERSION" ]; then
      # shellcheck disable=SC2296
      local -r __var_names_after=("${(k)__vars_after[@]}")
    else
      local -r __var_names_after=("${!__vars_after[@]}")
    fi

    for __sherpa_tmp_var_name in "${__var_names_after[@]}"; do
      # Skip ignored variables
      [[ -v VAR_NAMES_TO_IGNORE["$__sherpa_tmp_var_name"] ]] && continue
      # Skip unchanged variables
      [[ "${__vars_before[$__sherpa_tmp_var_name]}" == "${__vars_after[$__sherpa_tmp_var_name]}" ]] && continue

      echo "$__sherpa_tmp_var_name"
    done
  }

  __load_static() {
    local -r filter_pattern='^[[:space:]]*export[[:space:]]+[[:alnum:]_]+'

    # Cleanup:
    # export var_1 -> var_1
    grep -oE "$filter_pattern" "$SHERPA_ENV_FILENAME" | awk '{print $2}'
  }

  local variable_names

  if [ -n "$SHERPA_ENABLE_DYNAMIC_ENV_FILE_PARSING" ]; then
    variable_names=$(__load_dynamic)
  else
    variable_names=$(__load_static)
  fi

  [ -n "$variable_names" ] && echo "$variable_names"
}

_sherpa_fetch_aliase_names_from_env_file() {
  __load_dynamic() {
    # shellcheck disable=SC1090
    echo "$(unalias -a; source "$SHERPA_ENV_FILENAME"; compgen -a)"
  }

  __load_static() {
    local -r filter_pattern='^[[:space:]]*alias[[:space:]]'

    # Cleanup:
    # alias alias_1=... -> alias_1
    grep -E "$filter_pattern" "$SHERPA_ENV_FILENAME" | awk -F'[ =]' '{print $2}'
  }

  local alias_names

  if [ -n "$SHERPA_ENABLE_DYNAMIC_ENV_FILE_PARSING" ]; then
    alias_names=$(__load_dynamic)
  else
    alias_names=$(__load_static)
  fi

  [ -n "$alias_names" ] && echo "$alias_names"
}

_sherpa_fetch_function_names_from_env_file() {
  __load_dynamic() {
    if [ -n "$ZSH_VERSION" ]; then
      # Unsetting functions with compgen is not working in Zsh because the unset
      # removes compgen itself
      zsh --no-globalrcs --no-rcs -c 'source "$SHERPA_ENV_FILENAME"; print -l ${(k)functions}'
    else
      bash --noprofile --norc -c "source $SHERPA_ENV_FILENAME; compgen -A function"
    fi
  }

  __load_static() {
    local -r filter_pattern='^[[:space:]]*([[:alnum:]_]+[[:space:]]*\(\)|function[[:space:]]+[[:alnum:]_]+)'

    # Cleanup:
    # "function_1()" -> "function_1"
    # "function function_2()" -> "function_2()" -> "function_2"
    grep -oE "$filter_pattern" "$SHERPA_ENV_FILENAME" | \
      sed 's/function //' | \
      sed 's/()//'
  }

  local function_names

  if [ -n "$SHERPA_ENABLE_DYNAMIC_ENV_FILE_PARSING" ]; then
    function_names=$(__load_dynamic)
  else
    function_names=$(__load_static)
  fi

  [ -n "$function_names" ] && echo "$function_names"
}

_sherpa_parse_local_env_file() {
  _sherpa_fetch_variable_names_from_env_file
  _sherpa_fetch_aliase_names_from_env_file
  _sherpa_fetch_function_names_from_env_file
}
