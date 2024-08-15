sherpa() {
  if [ "$USE_SHERPA_DEV_VERSION" = true ]; then
    local -r version_info="Version: dev"
  else
    local -r version_info="Version: $SHERPA_VERSION"
  fi

  local -r usage_text="sherpa loads and unloads environment on a per-directory basis.

$version_info

Usage:
  sherpa <command> [options]

Basic Commands:
  trust          - Trust the current directory   | Aliases: t, allow, grant, permit
  untrust        - Untrust the current directory | Aliases: u, disallow, revoke, block, deny
  edit           - Edit the local env file       | Aliases: e, init
  off            - Turn Sherpa off               | Aliases: disable, sleep
  on             - Turn Sherpa on                | Aliases: enable, work
  symlink [PATH] - Symlink a local env file      | Aliases: link, slink
  reload         - Reload the local env          | Alias: r

Troubleshooting:
  status   - Show debug status info | Aliases: s, stat
  diagnose - Run local and global tests

Log levels:
  talk more   - Decrease the log level | Alias: -
  talk less   - Increase the log level | Alias: +
  debug       - Debug level            | Alias: dd
  shh         - Silence
  log         - Open the log options menu | Alias: talk
  log [LEVEL] - Set a specific log level  | Levels: debug, info, warn, error, silent | Alias: talk"

  local -r command="$1"
  case $command in
                     -h|--help|help|'') echo "$usage_text";;
            t|trust|allow|grant|permit) _sherpa_cli_trust;;
  u|untrust|disallow|revoke|block|deny) _sherpa_cli_untrust;;
                           e|edit|init) _sherpa_cli_edit;;
                     off|sleep|disable) _sherpa_cli_disable;;
                        on|work|enable) _sherpa_cli_enable;;
                              log|talk) shift; _sherpa_cli_set_log_level "$1";;
                              debug|dd) _sherpa_cli_set_log_level "$SHERPA_LOG_LEVEL_DEBUG";;
                                   shh) _sherpa_cli_set_log_level "$SHERPA_LOG_LEVEL_SILENT";;
                         s|stat|status) _sherpa_print_status;;
                              diagnose) _sherpa_cli_diagnose;;
                    symlink|link|slink) _sherpa_cli_symlink "$2";;
                              r|reload) _sherpa_cli_reload;;
                                     *) echo "Sherpa doesn't understand what you mean";;
  esac
}

_sherpa_cli_trust() {
  _sherpa_trust_current_dir && _sherpa_load_env_from_current_dir
}

_sherpa_cli_untrust() {
  _sherpa_unload_env_of_current_dir
  _sherpa_untrust_current_dir
}

_sherpa_cli_edit() {
  echo "hint: Waiting for your editor to close the file..."
  if [ -z "$EDITOR" ]; then
    _sherpa_log_warn "EDITOR is not set. Falling back to vi."
    vi "$SHERPA_ENV_FILENAME"
  else
    eval "$EDITOR $SHERPA_ENV_FILENAME"
  fi

  _sherpa_trust_current_dir &&
    _sherpa_unload_env_of_current_dir &&
    _sherpa_load_env_from_current_dir 2> /dev/null

  _sherpa_test_local_env_file_for_shell_errors
}

_sherpa_cli_disable() {
  _sherpa_unload_all_envs
  _sherpa_log_info "All envs are unloaded. Sherpa goes to sleep."
  _sherpa_save_global_config "SHERPA_ENABLED" false
}

_sherpa_cli_enable() {
  _sherpa_save_global_config "SHERPA_ENABLED" true

  if _sherpa_load_env_from_current_dir; then
    local -r current_env_copy="Local env is loaded. "
  fi

  _sherpa_log_info "${current_env_copy}Sherpa is ready for action."
}

_sherpa_cli_set_log_level() {
  case $1 in
   less|-) _sherpa_increase_log_level;;
   more|+) _sherpa_decrease_log_level;;
       '') _sherpa_cli_log_level_menu;;
        *) _sherpa_set_log_level "$1";;
  esac

  # Don't change the log level if the user ctrl-c'd the menu
  # shellcheck disable=SC2181
  [ $? -ne 0 ] && return 1

  _sherpa_log "Sherpa: Log level set to: $(_sherpa_get_log_level_in_text)"
}

_sherpa_cli_log_level_menu() {
  trap '__sherpa_cli_clear_last_lines 6; trap - SIGINT; return 1' SIGINT

  local -r current="\033[32m ❮ current\033[0m"

  echo "Select the log level:"
  echo -e "1) Debug$( [[ "$SHERPA_LOG_LEVEL" == "0" ]] && echo -e "$current " )"
  echo -e "2) Info$( [[ "$SHERPA_LOG_LEVEL" == "1" ]] && echo -e "$current " )"
  echo -e "3) Warn$( [[ "$SHERPA_LOG_LEVEL" == "2" ]] && echo -e "$current " )"
  echo -e "4) Error$( [[ "$SHERPA_LOG_LEVEL" == "3" ]] && echo -e "$current " )"
  echo -e "5) Silent 🤫$( [[ "$SHERPA_LOG_LEVEL" == "4" ]] && echo -e "$current " )"
  echo -n "Enter your choice [1-5]: "

  local choice

  if [[ -n $ZSH_VERSION ]]; then
    read -rk1 choice
  else
    read -rn1 choice
  fi

  trap - SIGINT

  __sherpa_cli_clear_last_lines 6

  local -r esc=$(printf "\033")
  if [[ "$choice" == "$esc" ]]; then
    return 1
  fi

  local -r enter=$'\n'
  if [[ "$choice" == "$enter" ]]; then
    __sherpa_cli_clear_last_lines 1
    return 1
  fi

  [[ "$choice" =~ ^[0-9]$ ]] && choice=$((choice - 1))

  _sherpa_set_log_level "$choice"
}

__sherpa_cli_clear_last_lines() {
  local -r number_of_lines_to_clear=$1

  echo -en "\033[2K"
  echo -en "\r"

  for _ in $(seq "$number_of_lines_to_clear"); do
    echo -en "\033[1A"
    echo -en "\033[2K"
  done
}

_sherpa_cli_diagnose() {
  if [ -n "$ZSH_VERSION" ]; then
    zsh -i "$SHERPA_DIR/bin/diagnose_zsh"
  else
    # To be able to stub the ~/.bashrc in the tests
    [ -z "$BASHRC_FILE" ] && BASHRC_FILE="$HOME/.bashrc"
    bash --rcfile "$BASHRC_FILE" -i "$SHERPA_DIR/bin/diagnose_bash"
  fi
}

_sherpa_cli_symlink() {
  local -r symlink_target="$1"

  if [ -f "$SHERPA_ENV_FILENAME" ]; then
    _sherpa_log_error "There is already a local env file in this directory." \
                            "Remove it before symlinking a new one."
    return 1
  fi

  if [ ! -e "$symlink_target" ]; then
    _sherpa_log_error "The target doesn't exist: $symlink_target"
    return 1
  fi

  if [ -d "$symlink_target" ]; then
    ln -s "$symlink_target/$SHERPA_ENV_FILENAME" "$SHERPA_ENV_FILENAME"
  else
    ln -s "$symlink_target" "$SHERPA_ENV_FILENAME"
  fi

  _sherpa_cli_trust > /dev/null &&
    _sherpa_log_info "Symlink is created. Local env is loaded."
}

_sherpa_cli_reload() {
  _sherpa_unload_env_of_current_dir && _sherpa_load_env_from_current_dir
}
