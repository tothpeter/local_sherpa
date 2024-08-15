_sherpa_utils::array::remove_first_element() {
  local -r array_name=$1

  # shellcheck disable=SC1087
  eval "$array_name=(\"\${$array_name[@]:1}\")"
}
