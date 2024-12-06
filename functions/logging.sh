#!/usr/bin/env bash
# logging.sh - A library of functions for colored logging with log levels.
# shellcheck disable=SC2034

# Color codes for styled output
readonly END="\033[0m"
readonly BLACK="\033[0;30m"
readonly BLACKB="\033[1;30m"
readonly WHITE="\033[0;37m"
readonly WHITEB="\033[1;37m"
readonly RED="\033[0;31m"
readonly REDB="\033[1;31m"
readonly GREEN="\033[0;32m"
readonly GREENB="\033[1;32m"
readonly YELLOW="\033[0;33m"
readonly YELLOWB="\033[1;33m"
readonly BLUE="\033[0;34m"
readonly BLUEB="\033[1;34m"
readonly PURPLE="\033[0;35m"
readonly PURPLEB="\033[1;35m"
readonly LIGHTBLUE="\033[0;36m"
readonly LIGHTBLUEB="\033[1;36m"

# Logging levels: DEBUG=0, INFO=1, WARNING=2, ERROR=3
readonly LOG_LEVEL=1       # Set the current logging threshold
readonly SILENT_MODE=false # Suppress all logs if set to true

# Logs a message with a specified level, color, and label.
# Arguments:
#   ${1}: Log level (DEBUG=0, INFO=1, WARNING=2, ERROR=3)
#   $2: Color for the message (e.g., LIGHTBLUEB, YELLOWB)
#   $3: Log label (e.g., DEBUG, INFO)
#   $4: The message to log
function log_message {
  local level=${1}
  local color=${2}
  local label=${3}
  local message=${4}

  # Print message if not in silent mode and level is sufficient
  if [ "${SILENT_MODE}" = false ] && (( level >= LOG_LEVEL )); then
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') ${color}[${label}]${END} ${message}"
  fi
}

# Logs a debug message (used for development and troubleshooting).
# Visible only if LOG_LEVEL=0 or lower.
# Arguments:
#   ${1}: The debug message to log
function print_debug {
  log_message 0 "${LIGHTBLUEB}" "DEBUG" "${1}"
}

# Logs an informational message (general application flow or updates).
# Visible if LOG_LEVEL=1 or lower.
# Arguments:
#   ${1}: The informational message to log
function print_info {
  log_message 1 "${BLUEB}" "INFO" "${1}"
}

# Logs a warning message (indicating potential issues or important notices).
# Visible if LOG_LEVEL=2 or lower.
# Arguments:
#   ${1}: The warning message to log
function print_warning {
  log_message 2 "${YELLOWB}" "WARNING" "${1}"
}

# Logs an error message (critical issues or failures).
# Visible if LOG_LEVEL=3 or lower.
# Arguments:
#   ${1}: The error message to log
function print_error {
  log_message 3 "${REDB}" "ERROR" "${1}"
}


# Logs a success message (used for positive outcomes or completions).
# Arguments:
#   ${1}: The success message to log
function print_success {
  if [ "${SILENT_MODE}" = false ]; then
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') ${GREENB}[SUCCESS]${END} ${1}"
  fi
}

# Logs a command execution message (useful for indicating actions being taken).
# Arguments:
#   ${1}: The command message to log
function print_command {
  if [ "${SILENT_MODE}" = false ]; then
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') ${PURPLEB}[COMMAND]${END} ${1}"
  fi
}
