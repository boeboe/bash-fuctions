#!/usr/bin/env bash
# args.sh - Functions to manage JSON-based arguments for Bash functions.
# shellcheck disable=SC1091

# Initialize an empty JSON structure for arguments
# Usage: init_args
# Output: {"args":[]}
function init_args() {
  echo '{"args":[]}'
}

# Add a key-value pair to the JSON structure
# Usage: add_arg <json> <key> <value>
# Output: Updated JSON with the new key-value pair
function add_arg() {
  local json="${1}"
  local key="${2}"
  local value="${3}"
  echo "${json}" | jq -c --arg key "${key}" --arg value "${value}" '.args += [{"key": $key, "value": $value}]'
}

# Retrieve the value of a specific key
# Usage: get_arg <json> <key>
# Output: The value associated with the key, or an empty string if not found
function get_arg() {
  local json="${1}"
  local key="${2}"
  echo "${json}" | jq -r --arg key "${key}" '.args[] | select(.key == $key) | .value // empty'
}

# Update the value of a specific key
# Usage: set_arg <json> <key> <new_value>
# Output: Updated JSON with the key's value modified
function set_arg() {
  local json="${1}"
  local key="${2}"
  local value="${3}"
  echo "${json}" | jq -c --arg key "${key}" --arg value "${value}" \
    '.args |= map(if .key == $key then .value = $value else . end)'
}

# Delete a specific key-value pair from the JSON structure
# Usage: delete_arg <json> <key>
# Output: Updated JSON without the specified key
function delete_arg() {
  local json="${1}"
  local key="${2}"
  echo "${json}" | jq -c --arg key "${key}" '.args |= map(select(.key != $key))'
}

# Verify mandatory arguments are present
# Usage: check_args <json> <mandatory_keys_array>
# Output: Error message for missing keys, or nothing if all keys are present
function check_args() {
  local json="${1}"
  shift
  local missing_keys=()
  for key in "${@}"; do
    if [[ -z $(get_arg "${json}" "${key}") ]]; then
      missing_keys+=("${key}")
    fi
  done
  if [[ ${#missing_keys[@]} -gt 0 ]]; then
    print_error "Missing mandatory arguments: ${missing_keys[*]}"
    return 1
  fi
}

# Print the raw JSON
# Usage: print_args <json>
function print_args() {
  local json="${1}"
  echo "${json}"
}

# Pretty print the JSON
# Usage: pretty_print_args <json>
function pretty_print_args() {
  local json="${1}"
  echo "${json}" | jq
}