#!/usr/bin/env bash
# test_yaml.sh - Unit tests for yaml.sh
# shellcheck disable=SC1091

set -euo pipefail

# Source the yaml.sh and logging.sh libraries
source "${FUNCTIONS_DIR}/yaml.sh"
source "${FUNCTIONS_DIR}/logging.sh"

# Initialize a variable to track failed tests
FAILED_TESTS=()

# Regex pattern for timestamp
TIMESTAMP_PATTERN="^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}"

# Regex pattern for ANSI color codes
COLOR_CODE_PATTERN="\x1B\[[0-9;]*m"

# Helper function to strip timestamp and color codes from the log
function strip_output() {
  local log="${1}"
  log=$(echo "${log}" | sed -E "s/${TIMESTAMP_PATTERN} //")
  log=$(echo "${log}" | sed -E "s/${COLOR_CODE_PATTERN}//g")
  echo "${log}"
}

# Helper function to test intermediate JSON
function test_yaml_to_intermediate() {
  local yaml_input="${1}"
  local expected_intermediate="${2}"
  local test_name="${3}"

  print_info "Running intermediate test: ${test_name}"
  local result
  result=$(yaml_to_intermediate "${yaml_input}")

  if [[ "${result}" == "${expected_intermediate}" ]]; then
    print_success "${test_name} passed."
  else
    print_error "${test_name} failed. Expected: ${expected_intermediate}, Got: ${result}"
    FAILED_TESTS+=("${test_name}")
  fi
}

# Helper function to test final JSON conversion
function test_yaml_to_json() {
  local yaml_input="${1}"
  local expected_final="${2}"
  local test_name="${3}"

  print_info "Running final JSON test: ${test_name}"
  local result
  result=$(yaml_to_json "${yaml_input}")

  if [[ "${result}" == "${expected_final}" ]]; then
    print_success "${test_name} passed."
  else
    print_error "${test_name} failed. Expected: ${expected_final}, Got: ${result}"
    FAILED_TESTS+=("${test_name}")
  fi
}

# Tests for yaml_to_intermediate and yaml_to_json
function run_all_tests() {
  local yaml_input expected_intermediate expected_final

  # Test: Key-Value Parsing
  yaml_input="key1: value1"
  expected_intermediate='[{"type":"key_value","indentation":0,"key":"key1","value":"value1"}]'
  expected_final='{"key1":"value1"}'
  test_yaml_to_intermediate "${yaml_input}" "${expected_intermediate}" "test_intermediate_key_value_parsing"
  test_yaml_to_json "${yaml_input}" "${expected_final}" "test_final_key_value_parsing"

  # Test: YAML List Parsing
  yaml_input=$'list_key:\n  - item1\n  - item2'
  expected_intermediate=$'[{"type":"key_only","indentation":0,"key":"list_key"},{"type":"list_item","indentation":2,"value":"item1"},{"type":"list_item","indentation":2,"value":"item2"}]'
  expected_final='{"list_key":["item1","item2"]}'
  test_yaml_to_intermediate "${yaml_input}" "${expected_intermediate}" "test_intermediate_list_parsing"
  test_yaml_to_json "${yaml_input}" "${expected_final}" "test_final_list_parsing"

  # Test: Nested Objects Parsing
  yaml_input=$'nested_key:\n  subkey1: value1\n  subkey2: value2'
  expected_intermediate=$'[{"type":"key_only","indentation":0,"key":"nested_key"},{"type":"key_value","indentation":2,"key":"subkey1","value":"value1"},{"type":"key_value","indentation":2,"key":"subkey2","value":"value2"}]'
  expected_final='{"nested_key":{"subkey1":"value1","subkey2":"value2"}}'
  test_yaml_to_intermediate "${yaml_input}" "${expected_intermediate}" "test_intermediate_nested_objects_parsing"
  test_yaml_to_json "${yaml_input}" "${expected_final}" "test_final_nested_objects_parsing"

  # Test: Block Scalar Parsing
  yaml_input=$'block_scalar: |\n  This is\n  a multiline\n  block scalar'
  expected_intermediate=$'[{"type":"block_scalar","indentation":0,"key":"block_scalar"},{"type":"block_scalar_line","indentation":2,"content":"This is"},{"type":"block_scalar_line","indentation":2,"content":"a multiline"},{"type":"block_scalar_line","indentation":2,"content":"block scalar"}]'
  expected_final='{"block_scalar":"This is\\na multiline\\nblock scalar\\n"}'
  test_yaml_to_intermediate "${yaml_input}" "${expected_intermediate}" "test_intermediate_block_scalar_parsing"
  test_yaml_to_json "${yaml_input}" "${expected_final}" "test_final_block_scalar_parsing"

  # Test: Comments Parsing
  yaml_input=$'# This is a comment\nkey: value'
  expected_intermediate=$'[{"type":"comment","indentation":0},{"type":"key_value","indentation":0,"key":"key","value":"value"}]'
  expected_final='{"key":"value"}'
  test_yaml_to_intermediate "${yaml_input}" "${expected_intermediate}" "test_intermediate_comments_parsing"
  test_yaml_to_json "${yaml_input}" "${expected_final}" "test_final_comments_parsing"

  # Test: Empty Lines Parsing
  yaml_input=$'key1: value1\n\nkey2: value2'
  expected_intermediate=$'[{"type":"key_value","indentation":0,"key":"key1","value":"value1"},{"type":"empty","indentation":0},{"type":"key_value","indentation":0,"key":"key2","value":"value2"}]'
  expected_final='{"key1":"value1","key2":"value2"}'
  test_yaml_to_intermediate "${yaml_input}" "${expected_intermediate}" "test_intermediate_empty_lines_parsing"
  test_yaml_to_json "${yaml_input}" "${expected_final}" "test_final_empty_lines_parsing"

  # Test: Document Boundaries Parsing
  yaml_input=$'---\nkey1: value1\n...'
  expected_intermediate=$'[{"type":"document_boundary","indentation":0},{"type":"key_value","indentation":0,"key":"key1","value":"value1"},{"type":"document_boundary","indentation":0}]'
  expected_final='{"key1":"value1"}'
  test_yaml_to_intermediate "${yaml_input}" "${expected_intermediate}" "test_intermediate_document_boundaries_parsing"
  test_yaml_to_json "${yaml_input}" "${expected_final}" "test_final_document_boundaries_parsing"

  # Test: Unknown Line Parsing
  yaml_input=$'unknown line content\nkey: value'
  expected_intermediate=$'[{"type":"unknown","indentation":0,"line":"unknown line content"},{"type":"key_value","indentation":0,"key":"key","value":"value"}]'
  expected_final='{"key":"value"}'
  test_yaml_to_intermediate "${yaml_input}" "${expected_intermediate}" "test_intermediate_unknown_line_parsing"
  test_yaml_to_json "${yaml_input}" "${expected_final}" "test_final_unknown_line_parsing"
}

# Run all tests
function run_tests() {
  print_info "Starting unit tests for yaml.sh"

  run_all_tests

  if [[ ${#FAILED_TESTS[@]} -eq 0 ]]; then
    print_success "All tests passed successfully!"
  else
    print_error "The following tests failed: ${FAILED_TESTS[*]}"
    exit 1
  fi
}

run_tests