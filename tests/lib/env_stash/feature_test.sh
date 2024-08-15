source tests/support/test_helper.sh
source "$SHERPA_DIR/lib/env_stash/utils.sh"
source "$SHERPA_DIR/lib/env_stash/aliases.sh"
source "$SHERPA_DIR/lib/env_stash/functions.sh"
source "$SHERPA_DIR/lib/env_stash/variables.sh"


# 〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰
#               Stashing and unstashing exported common variables
# 〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰

export exported_existing_variable1="exported_existing_variable1 original content"
export exported_existing_variable2="exported_existing_variable2 original content"

sherpa::env_stash.stash_variables "$PWD" "exported_existing_variable1" \
                                         "exported_existing_variable2" \
                                         "new_exported_variable1" \
                                         "new_exported_variable2"

exported_existing_variable1="CHANGED 1"
exported_existing_variable2="CHANGED 2"
export new_exported_variable1="new_exported_variable1 content"
export new_exported_variable2="new_exported_variable2 content"

# ==============================================================================
# ++++ Senety check
assert_equal "$exported_existing_variable1" "CHANGED 1" "The existed variable1 changed"
assert_equal "$exported_existing_variable2" "CHANGED 2" "The existed variable2 changed"
assert_equal "$new_exported_variable1" "new_exported_variable1 content" "The new variable1 is set"
assert_equal "$new_exported_variable2" "new_exported_variable2 content" "The new variable2 is set"

sherpa::env_stash.unstash_all "$PWD"

# ==============================================================================
# ++++ It restores the overwritten variables
assert_equal "$exported_existing_variable1" "exported_existing_variable1 original content" "The existed variable1 is restored"
assert_equal "$exported_existing_variable2" "exported_existing_variable2 original content" "The existed variable2 is restored"

# ==============================================================================
# ++++ It removes the variables which did not exist at the time of stashing
assert_undefined "new_exported_variable1" "The new variable1 is removed"
assert_undefined "new_exported_variable2" "The new variable2 is removed"


# 〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰
#             Stashing and unstashing NON exported common variables
# 〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰

existing_variable1="existing_variable1 original content"
existing_variable2="existing_variable2 original content"

sherpa::env_stash.stash_variables "$PWD" "existing_variable1" \
                                         "existing_variable2" \
                                         "new_variable1" \
                                         "new_variable2"

existing_variable1="CHANGED 1"
existing_variable2="CHANGED 2"
new_variable1="new_variable1 content"
new_variable2="new_variable2 content"

# ==============================================================================
# ++++ Senety check
assert_equal "$existing_variable1" "CHANGED 1" "The existed variable1 changed"
assert_equal "$existing_variable2" "CHANGED 2" "The existed variable2 changed"
assert_equal "$new_variable1" "new_variable1 content" "The new variable1 is set"
assert_equal "$new_variable2" "new_variable2 content" "The new variable2 is set"

sherpa::env_stash.unstash_all "$PWD"

# ==============================================================================
# ++++ It restores the overwritten variables
assert_equal "$existing_variable1" "existing_variable1 original content" "The existed variable1 is restored"
assert_equal "$existing_variable2" "existing_variable2 original content" "The existed variable2 is restored"

# ==============================================================================
# ++++ It removes the variables which did not exist at the time of stashing
assert_undefined "new_variable1" "The new variable1 is removed"
assert_undefined "new_variable2" "The new variable2 is removed"


# 〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰
#                     Stashing and unstashing indexed arrays
# 〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰

declare -a existing_indexed_array1=("existing_indexed_array1 original content")
declare -a existing_indexed_array2=("existing_indexed_array2 original content")

export existing_indexed_array1 existing_indexed_array2

sherpa::env_stash.stash_variables "$PWD" "existing_indexed_array1" \
                                         "existing_indexed_array2" \
                                         "new_indexed_array1" \
                                         "new_indexed_array2"

existing_indexed_array1=("CHANGED 1")
existing_indexed_array2=("CHANGED 2")

declare -a new_indexed_array1=("new_indexed_array1 content")
declare -a new_indexed_array2=("new_indexed_array2 content")

export new_indexed_array1 new_indexed_array2

# ==============================================================================
# ++++ Senety check
assert_equal "${existing_indexed_array1[@]}" "CHANGED 1" "The existed indexed array1 changed"
assert_equal "${existing_indexed_array2[@]}" "CHANGED 2" "The existed indexed array2 changed"
assert_equal "${new_indexed_array1[@]}" "new_indexed_array1 content" "The new indexed array1 is set"
assert_equal "${new_indexed_array2[@]}" "new_indexed_array2 content" "The new indexed array2 is set"

sherpa::env_stash.unstash_all "$PWD"

# ==============================================================================
# ++++ It restores the overwritten variables
assert_equal "${existing_indexed_array1[@]}" "existing_indexed_array1 original content" "The existed indexed array1 is restored"
assert_equal "${existing_indexed_array2[@]}" "existing_indexed_array2 original content" "The existed indexed array2 is restored"

# ==============================================================================
# ++++ It removes the variables which did not exist at the time of stashing
assert_undefined "new_indexed_array1" "The new indexed array1 is removed"
assert_undefined "new_indexed_array2" "The new indexed array2 is removed"


# 〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰
#                     Stashing and unstashing indexed arrays
# 〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰

declare -a existing_indexed_array1=("existing_indexed_array1 original content")

sherpa::env_stash.stash_variables "$PWD" "existing_indexed_array1"

# shellcheck disable=SC2178
existing_indexed_array1="Not an indexed array"

# ==============================================================================
# ++++ Senety check
# shellcheck disable=SC2128
assert_equal "$existing_indexed_array1" "Not an indexed array" "The existed indexed array1 changed"

sherpa::env_stash.unstash_all "$PWD"

# ==============================================================================
# ++++ It restores the type of the overwritten variables
assert_equal "${existing_indexed_array1[@]}" "existing_indexed_array1 original content" "The existed indexed array1 is restored"


# 〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰
#                   Stashing and unstashing associative arrays
# 〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰

declare -A existing_associative_array1=([key1]="existing_associative_array1 original content")
declare -A existing_associative_array2=([key2]="existing_associative_array2 original content")

export existing_associative_array1 existing_associative_array2

sherpa::env_stash.stash_variables "$PWD" "existing_associative_array1" \
                                         "existing_associative_array2" \
                                         "new_associative_array1" \
                                         "new_associative_array2"

existing_associative_array1=([key1]="CHANGED 1")
existing_associative_array2=([key2]="CHANGED 2")

declare -A new_associative_array1=([key1]="new_associative_array1 content")
declare -A new_associative_array2=([key2]="new_associative_array2 content")

export new_associative_array1 new_associative_array2

# ==============================================================================
# ++++ Senety check
assert_equal "${existing_associative_array1[key1]}" "CHANGED 1" "The existed associative array1 changed"
assert_equal "${existing_associative_array2[key2]}" "CHANGED 2" "The existed associative array2 changed"
assert_equal "${new_associative_array1[key1]}" "new_associative_array1 content" "The new associative array1 is set"
assert_equal "${new_associative_array2[key2]}" "new_associative_array2 content" "The new associative array2 is set"

sherpa::env_stash.unstash_all "$PWD"

# ==============================================================================
# ++++ It restores the overwritten variables
assert_equal "${existing_associative_array1[key1]}" "existing_associative_array1 original content" "The existed associative array1 is restored"
assert_equal "${existing_associative_array2[key2]}" "existing_associative_array2 original content" "The existed associative array2 is restored"

# ==============================================================================
# ++++ It removes the variables which did not exist at the time of stashing
assert_undefined "new_associative_array1" "The new associative array1 is removed"
assert_undefined "new_associative_array2" "The new associative array2 is removed"


# 〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰
#                        Stashing and unstashing aliases
# 〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰

alias existing_alias1="echo existing_alias1 original content"
alias existing_alias2="echo existing_alias2 original content"

sherpa::env_stash.stash_aliases "$PWD" "existing_alias1" \
                                       "existing_alias2" \
                                       "new_alias1" \
                                       "new_alias2"

alias existing_alias1="echo CHANGED 1"
alias existing_alias2="echo CHANGED 2"
alias new_alias1="echo new_alias1 content"
alias new_alias2="echo new_alias2 content"

# ==============================================================================
# ++++ Senety check
assert_equal "$(existing_alias1)" "CHANGED 1" "The existed alias1 changed"
assert_equal "$(existing_alias2)" "CHANGED 2" "The existed alias2 changed"
assert_equal "$(new_alias1)" "new_alias1 content" "The new alias1 is set"
assert_equal "$(new_alias2)" "new_alias2 content" "The new alias2 is set"

sherpa::env_stash.unstash_all "$PWD"

# ==============================================================================
# ++++ It restores the overwritten aliases
assert_equal "$(existing_alias1)" "existing_alias1 original content" "The existed alias1 is restored"
assert_equal "$(existing_alias2)" "existing_alias2 original content" "The existed alias2 is restored"

# ==============================================================================
# ++++ It removes the aliases which did not exist at the time of stashing
assert_undefined "new_alias1" "The new alias1 is removed"
assert_undefined "new_alias2" "The new alias2 is removed"


# 〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰
#                       Stashing and unstashing functions
# 〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰

# shellcheck disable=SC2317
existing_function1() { echo "existing_function1 original content"; }
# shellcheck disable=SC2317
existing_function2() { echo "existing_function2 original content"; }

sherpa::env_stash.stash_functions "$PWD" "existing_function1" \
                                         "existing_function2" \
                                         "new_function1" \
                                         "new_function2"


existing_function1() { echo "CHANGED 1"; }
existing_function2() { echo "CHANGED 2"; }

new_function1() { echo "new_function1 content"; }
new_function2() { echo "new_function2 content"; }

# ==============================================================================
# ++++ Senety check
assert_equal "$(existing_function1)" "CHANGED 1" "The existing_function1 changed"
assert_equal "$(existing_function2)" "CHANGED 2" "The existing_function2 changed"
assert_equal "$(new_function1)" "new_function1 content" "The new function 1 is set"
assert_equal "$(new_function2)" "new_function2 content" "The new function 2 is set"

sherpa::env_stash.unstash_all "$PWD"

# ==============================================================================
# ++++ It restores the overwritten functiones
assert_equal "$(existing_function1)" "existing_function1 original content" "The existed function1 is restored"
assert_equal "$(existing_function2)" "existing_function2 original content" "The existed function2 is restored"

# ==============================================================================
# ++++ It removes the functiones which did not exist at the time of stashing
assert_undefined "new_function1" "The new function 1 is removed"
assert_undefined "new_function2" "The new function 2 is removed"
