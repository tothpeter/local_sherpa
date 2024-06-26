# It returns a list of: variable, function and alias names
parse_local_env_file() {
  _fetch_variable_names
  _fetch_aliase_names
  _fetch_function_names
}

_fetch_variable_names() {
  local filter_pattern='^[[:space:]]*export[[:space:]]+[[:alnum:]_]+'
  # Cleanup:
  # export var_1 -> var_1
  local variable_names=$(grep -oE "$filter_pattern" .local-sherpa | \
                         awk '{print $2}')

  echo "$variable_names"
}

_fetch_aliase_names() {
  local filter_pattern='^[[:space:]]*alias[[:space:]]'
  # Cleanup:
  # alias alias_1=... -> alias_1
  local alias_names=$(grep -E "$filter_pattern" .local-sherpa | \
                      awk -F'[ =]' '{print $2}')
  echo "$alias_names"
}

_fetch_function_names() {
  local filter_pattern='^[[:space:]]*([[:alnum:]_]+[[:space:]]*\(\)|function[[:space:]]+[[:alnum:]_]+)'
  # Cleanup:
  # function_1() -> function_1
  # function function_2() -> function_2() -> function_2
  local function_names=$(grep -oE "$filter_pattern" .local-sherpa | \
                         sed 's/function //' | \
                         sed 's/()//')
  echo "$function_names"
}
