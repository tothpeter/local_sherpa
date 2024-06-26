source tests/support/init.sh

plan_no_plan

# Setup
cd playground/project_1
sherpa trust
is "$var_1" "LOCAL VAR PROJECT 1" "The local env is loaded"


# When editing the local env file with Sherpa
# It opens the default editor
EDITOR="sed -i '' '1s/ 1/ 8/'" sherpa edit > /dev/null

# When the user saves and closes the local env file
# Sherpa auto trusts the local env file and loads it
is "$var_1" "LOCAL VAR PROJECT 8" "The updated local env is re-trusted and reloaded"


# Tear down
rm -rf $SHERPA_CHECKSUM_DIR
git checkout -- .local-sherpa
