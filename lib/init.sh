if [ -n "$ZSH_VERSION" ]; then
  SHERPA_LIB_DIR=$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )
else
  SHERPA_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

SHERPA_DIR="$(dirname "$SHERPA_LIB_DIR")"

# shellcheck disable=SC2034
SHERPA_CHECKSUM_DIR="$HOME/.local/share/local_sherpa"
SHERPA_CONFIG_DIR="${SHERPA_CONFIG_DIR:-"$HOME/.config/local_sherpa"}"
export SHERPA_ENV_FILENAME="${SHERPA_ENV_FILENAME:-.envrc}"

SHERPA_LOADED_ENV_DIRS=()

source "$SHERPA_LIB_DIR/global_config.sh"
_sherpa_load_global_config "SHERPA_ENABLED" true

source "$SHERPA_LIB_DIR/logger.sh"
_sherpa_load_global_config "SHERPA_LOG_LEVEL" "$SHERPA_LOG_LEVEL_INFO"

# Load the app
source "$SHERPA_LIB_DIR/utils.sh"

source "$SHERPA_LIB_DIR/trust_verification.sh"
source "$SHERPA_LIB_DIR/env_stash/utils.sh"
source "$SHERPA_LIB_DIR/env_stash/variables.sh"
source "$SHERPA_LIB_DIR/env_stash/aliases.sh"
source "$SHERPA_LIB_DIR/env_stash/functions.sh"
source "$SHERPA_LIB_DIR/local_env_file_parser.sh"
source "$SHERPA_LIB_DIR/setup_cd_hook.sh"
source "$SHERPA_LIB_DIR/status.sh"
source "$SHERPA_LIB_DIR/load_unload.sh"

source "$SHERPA_LIB_DIR/cli.sh"

if [ -n "$ZSH_VERSION" ]; then
  # To make compgen available in zsh
  autoload -Uz +X bashcompinit && bashcompinit
fi

# Hook into cd
_sherpa_setup_cd_hook

# Skip loading the local env 2 times for Bash when loading the shell the first time
if [ -n "$ZSH_VERSION" ]; then
  _sherpa_load_env_from_current_dir
fi
