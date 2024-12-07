#!/usr/bin/env bash
# yaml.sh - A library of functions for YAML-to-JSON parsing.

# YAML Line Types
readonly YAML_COMMENT_RE="^[[:space:]]*#.*$"
readonly YAML_EMPTY_LINE_RE="^[[:space:]]*$"
readonly YAML_KEY_VALUE_RE="^[[:space:]]*([^:]+):[[:space:]]*([^[:space:]].*)$"
readonly YAML_KEY_ONLY_RE="^[[:space:]]*([^:]+):[[:space:]]*$"
readonly YAML_LIST_ITEM_RE="^[[:space:]]*-[[:space:]]*(.*)$"
readonly YAML_BLOCK_SCALAR_RE="^[[:space:]]*([^:]+):[[:space:]]*[|>][[:space:]]*$"
readonly YAML_INDENTATION_RE="^([[:space:]]*).*"
readonly YAML_DOCUMENT_BOUNDARY_RE="^[[:space:]]*(---|...)$"

# Global variable to hold intermediate JSON structure
INTERMEDIATE_JSON="[]"

# Parse YAML to JSON (entry point for end users)
# Usage: yaml_to_json <yaml_string>
function yaml_to_json() {
  local yaml_string="${1}"

  # Step 1: Generate intermediate JSON
  local intermediate_json
  intermediate_json=$(yaml_to_intermediate "${yaml_string}")

  # Step 2: Convert intermediate JSON to final JSON
  local final_json
  final_json=$(intermediate_to_json "${intermediate_json}")

  # Output the final JSON
  echo "${final_json}"
}

# Parse a YAML string and generate intermediate JSON
# Usage: yaml_to_intermediate <yaml_string>
function yaml_to_intermediate() {
  local yaml_string="${1}"
  INTERMEDIATE_JSON="[]"

  while IFS= read -r line; do
    process_line "${line}"
  done <<< "${yaml_string}"

  echo "${INTERMEDIATE_JSON}"
}

# Process a single line of YAML
function process_line() {
  local line="${1}"

  # Determine indentation level using length of leading spaces
  local indent
  indent=$(echo "${line}" | sed -E "s/${YAML_INDENTATION_RE}/\1/" | awk '{print length}')

  # Classify the line type
  local line_type
  line_type=$(classify_line "${line}")

  # Log the process for debugging
  # print_info "Processing line: '${line}'"
  # print_info "Indentation: ${indent}, Line type: ${line_type}"

  # Delegate to appropriate handler function
  case "${line_type}" in
    "comment")
      handle_comment "${line}" "${indent}"
      ;;
    "empty")
      handle_empty_line "${line}" "${indent}"
      ;;
    "key_value")
      handle_key_value "${line}" "${indent}"
      ;;
    "key_only")
      handle_key_only "${line}" "${indent}"
      ;;
    "list_item")
      handle_list_item "${line}" "${indent}"
      ;;
    "block_scalar")
      handle_block_scalar "${line}" "${indent}"
      ;;
    "document_boundary")
      handle_document_boundary "${line}" "${indent}"
      ;;
    "unknown")
      handle_unknown "${line}" "${indent}"
      ;;
    *)
      print_error "Unrecognized line type: ${line}"
      ;;
  esac
}

# Classify a line to determine its type
function classify_line() {
  local line="${1}"

  if [[ "${line}" =~ ${YAML_COMMENT_RE} ]]; then
    echo "comment"
  elif [[ "${line}" =~ ${YAML_EMPTY_LINE_RE} ]]; then
    echo "empty"
  elif [[ "${line}" =~ ${YAML_DOCUMENT_BOUNDARY_RE} ]]; then
    echo "document_boundary"
  elif [[ "${line}" =~ ${YAML_BLOCK_SCALAR_RE} ]]; then
    echo "block_scalar"
  elif [[ "${line}" =~ ${YAML_KEY_VALUE_RE} ]]; then
    echo "key_value"
  elif [[ "${line}" =~ ${YAML_KEY_ONLY_RE} ]]; then
    echo "key_only"
  elif [[ "${line}" =~ ${YAML_LIST_ITEM_RE} ]]; then
    echo "list_item"
  else
    print_error "Skipping unsupported type: ${line}"
    echo "unknown"
  fi
}

# Convert intermediate JSON to final JSON
# Usage: intermediate_to_json <intermediate_json>
function intermediate_to_json() {
  local intermediate_json="${1}"
  local result="{}"

  # Process each entry in the intermediate JSON
  for ((i = 0; i < $(echo "${intermediate_json}" | jq 'length // 0'); i++)); do
    local entry
    entry=$(echo "${intermediate_json}" | jq .["${i}"])

    # Extract the type and handle accordingly
    local type
    type=$(echo "${entry}" | jq -r .type)

    case "${type}" in
      "key_value")
        local key value parent_key
        key=$(echo "${entry}" | jq -r .key)
        value=$(echo "${entry}" | jq -r .value)
        parent_key=$(find_parent_key "${intermediate_json}" "${i}")

        if [[ -z "${parent_key}" ]]; then
          # Add key-value at the root level
          result=$(echo "${result}" | jq -c --arg key "${key}" --arg value "${value}" '.[$key] = $value')
        else
          # Add key-value under the parent key
          result=$(echo "${result}" | jq -c --arg parent_key "${parent_key}" --arg key "${key}" --arg value "${value}" '
            .[$parent_key][$key] = $value
          ')
        fi
        ;;
      "key_only")
        local key parent_key
        key=$(echo "${entry}" | jq -r .key)
        parent_key=$(find_parent_key "${intermediate_json}" "${i}")

        if [[ -z "${parent_key}" ]]; then
          # Add as a new object at the root level
          result=$(echo "${result}" | jq -c --arg key "${key}" '.[$key] = {}')
        else
          # Add as a nested object under the parent key
          result=$(echo "${result}" | jq -c --arg parent_key "${parent_key}" --arg key "${key}" '
            .[$parent_key][$key] = {}
          ')
        fi
        ;;
      "list_item")
        local value parent_key
        value=$(echo "${entry}" | jq -r .value)
        parent_key=$(find_parent_key "${intermediate_json}" "${i}")

        if [[ -z "${parent_key}" ]]; then
          print_error "No valid parent key found for index ${i} while handling list_item"
          continue
        fi

        # Ensure parent key is initialized as an array
        result=$(echo "${result}" | jq -c --arg parent_key "${parent_key}" '
          if .[$parent_key] == null or (.[$parent_key] | type != "array") then .[$parent_key] = [] else . end
        ')

        # Append the list item to the parent key
        result=$(echo "${result}" | jq -c --arg parent_key "${parent_key}" --arg value "${value}" '.[$parent_key] += [$value]')
        ;;
      "block_scalar")
        # Handle block scalar if necessary
        ;;
      *)
        print_error "Skipping unsupported type: ${type}"
        ;;
    esac
  done

  echo "${result}"
}

# Find the parent key for a nested entry or list item based on indentation
# Usage: find_parent_key <intermediate_json> <current_index>
function find_parent_key() {
  local intermediate_json="${1}"
  local index="${2}"

  # Get the current entry's indentation level
  local current_indent
  current_indent=$(echo "${intermediate_json}" | jq -r ".[$index].indentation")

  # Traverse backwards to find the closest valid parent key
  for ((j = index - 1; j >= 0; j--)); do
    local entry
    entry=$(echo "${intermediate_json}" | jq .["${j}"])
    local entry_indent
    entry_indent=$(echo "${entry}" | jq -r .indentation)

    # Check if the entry's indentation is less than the current entry
    if (( entry_indent < current_indent )); then
      local entry_type
      entry_type=$(echo "${entry}" | jq -r .type)

      # Valid parent types are "key_only" or "key_value"
      if [[ "${entry_type}" == "key_only" || "${entry_type}" == "key_value" ]]; then
        echo "${entry}" | jq -r .key
        return
      fi
    fi
  done

  # If no valid parent key is found
  echo ""
}

# Handlers for different line types
function handle_comment() {
  local line="${1}"
  local indent="${2}"
  INTERMEDIATE_JSON=$(echo "${INTERMEDIATE_JSON}" | jq -c --arg type "comment" --arg indent "${indent}" '. += [{"type": $type, "indentation": ($indent | tonumber)}]')
}

function handle_empty_line() {
  local line="${1}"
  local indent="${2}"
  INTERMEDIATE_JSON=$(echo "${INTERMEDIATE_JSON}" | jq -c --arg type "empty" --arg indent "${indent}" '. += [{"type": $type, "indentation": ($indent | tonumber)}]')
}

function handle_key_value() {
  local line="${1}"
  local indent="${2}"
  local key value
  key=$(extract_key "${line}")
  value=$(extract_value "${line}")
  INTERMEDIATE_JSON=$(echo "${INTERMEDIATE_JSON}" | jq -c --arg type "key_value" --arg indent "${indent}" --arg key "${key}" --arg value "${value}" '. += [{"type": $type, "indentation": ($indent | tonumber), "key": $key, "value": $value}]')
}

function handle_key_only() {
  local line="${1}"
  local indent="${2}"
  local key
  key=$(echo "${line}" | sed -E "s/${YAML_KEY_ONLY_RE}/\1/")
  INTERMEDIATE_JSON=$(echo "${INTERMEDIATE_JSON}" | jq -c --arg type "key_only" --arg indent "${indent}" --arg key "${key}" '. += [{"type": $type, "indentation": ($indent | tonumber), "key": $key}]')
}

function handle_list_item() {
  local line="${1}"
  local indent="${2}"
  local value
  value=$(echo "${line}" | sed -E "s/${YAML_LIST_ITEM_RE}/\1/")
  INTERMEDIATE_JSON=$(echo "${INTERMEDIATE_JSON}" | jq -c --arg type "list_item" --arg indent "${indent}" --arg value "${value}" '. += [{"type": $type, "indentation": ($indent | tonumber), "value": $value}]')
}

function handle_block_scalar() {
  local line="${1}"
  local indent="${2}"
  local key
  key=$(extract_key "${line}")
  INTERMEDIATE_JSON=$(echo "${INTERMEDIATE_JSON}" | jq -c --arg type "block_scalar" --arg indent "${indent}" --arg key "${key}" '. += [{"type": $type, "indentation": ($indent | tonumber), "key": $key}]')
}

function handle_document_boundary() {
  local line="${1}"
  local indent="${2}"
  INTERMEDIATE_JSON=$(echo "${INTERMEDIATE_JSON}" | jq -c --arg type "document_boundary" --arg indent "${indent}" '. += [{"type": $type, "indentation": ($indent | tonumber)}]')
}

function handle_unknown() {
  local line="${1}"
  local indent="${2}"
  INTERMEDIATE_JSON=$(echo "${INTERMEDIATE_JSON}" | jq -c --arg type "unknown" --arg indent "${indent}" --arg line "${line}" '. += [{"type": $type, "indentation": ($indent | tonumber), "line": $line}]')
}

# Extract key from a key-value pair
function extract_key() {
  local line="${1}"
  echo "${line}" | sed -E "s/${YAML_KEY_VALUE_RE}/\1/"
}

# Extract value from a key-value pair
function extract_value() {
  local line="${1}"
  echo "${line}" | sed -E "s/${YAML_KEY_VALUE_RE}/\2/"
}