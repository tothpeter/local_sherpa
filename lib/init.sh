#!/usr/bin/env zsh

export SHERPA_ENABLED=true
export SHERPA_LOG_LEVEL='info' # debug, info, no talking

if [ -n "$ZSH_VERSION" ]; then
  SHERPA_LIB_PATH=$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )
else
  SHERPA_LIB_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

SHERPA_PATH="$(dirname "$SHERPA_LIB_PATH")"

SHERPA_CHECKSUM_DIR="$HOME/.local/share/local_sherpa"

# Load the dependencies
source "$SHERPA_PATH/vendor/smartcd/arrays"
source "$SHERPA_PATH/vendor/smartcd/varstash"

# Load the app
source $SHERPA_LIB_PATH/logger.sh
source $SHERPA_LIB_PATH/trust_verification.sh
source $SHERPA_LIB_PATH/local_env_file_parser.sh
source $SHERPA_LIB_PATH/setup_cd_hook.sh

source "$SHERPA_LIB_PATH/sherpa.sh"

# Hook into cd
setup_cd_hook

# Skip loading the local env 2 times for Bash when loading the shell the first time
if [ -n "$ZSH_VERSION" ]; then
  load_local_env
fi
