source tests/support/app_helper.sh

# 〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰
#                          Local environment reloading
# 〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰
stub_local_env_file 'alias alias_1="echo alias_1"'
cd /
sherpa trust

# ++++ Senety checks: the local environment file is loaded
is "$(alias_1)" "alias_1"

# When the local env file gets changed and trusted somewhere else
stub_local_env_file 'alias alias_2="echo changed"'
_sherpa_trust_current_dir

# ++++ It reloads the environment for the current directory
sherpa reload

is_undefined "alias_1"
is "$(alias_2)" "changed"
