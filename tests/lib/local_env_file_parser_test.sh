source tests/support/init.sh

plan_no_plan

# Setup
cd fixtures/parsing


expected_list="var_1
VAR_2
var_multi_line
alias_1
ALIAS_2
alias_multi_line
function_1
FUNCTION_2
function_3
function_with_comment"

actual_list=$(parse_local_env_file)

is "$actual_list" "$expected_list" "Correct list of variable, function and alias names"
