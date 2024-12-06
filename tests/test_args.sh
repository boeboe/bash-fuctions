#!/usr/bin/env bash
# test_args.sh - Unit tests for args.sh
# shellcheck disable=SC1091

set -euo pipefail

# Source the arguments library and logging library
source "${FUNCTIONS_DIR}/args.sh"
source "${FUNCTIONS_DIR}/logging.sh"

# Initialize a variable to track failed tests
FAILED_TESTS=()

# Regex pattern for timestamp (adjust according to your format)
TIMESTAMP_PATTERN="^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}"

# Regex pattern for ANSI color codes
COLOR_CODE_PATTERN="\x1B\[[0-9;]*m"

# Helper function to strip timestamp and color codes from the log
function strip_output() {
  local log="${1}"
  # Remove timestamp
  log=$(echo "${log}" | sed -E "s/${TIMESTAMP_PATTERN} //")
  # Remove ANSI color codes
  log=$(echo "${log}" | sed -E "s/${COLOR_CODE_PATTERN}//g")
  echo "${log}"
}

# Test init_args
function test_init_args() {
  local expected='{"args":[]}'
  print_info "Running test: test_init_args"

  local result
  result=$(init_args)

  if [[ "${result}" == "${expected}" ]]; then
    print_success "test_init_args passed."
  else
    print_error "test_init_args failed. Expected: ${expected}, Got: ${result}"
    FAILED_TESTS+=("test_init_args")
  fi
}

# Test add_arg
function test_add_arg() {
  local json='{"args":[]}'
  local key="arg1"
  local value="value1"
  local expected='{"args":[{"key":"arg1","value":"value1"}]}'
  print_info "Running test: test_add_arg"

  local result
  result=$(add_arg "${json}" "${key}" "${value}")

  if [[ "${result}" == "${expected}" ]]; then
    print_success "test_add_arg passed."
  else
    print_error "test_add_arg failed. Expected: ${expected}, Got: ${result}"
    FAILED_TESTS+=("test_add_arg")
  fi
}

# Test get_arg
function test_get_arg() {
  local json='{"args":[{"key":"arg1","value":"value1"}]}'
  local key="arg1"
  local expected="value1"
  print_info "Running test: test_get_arg"

  local result
  result=$(get_arg "${json}" "${key}")

  if [[ "${result}" == "${expected}" ]]; then
    print_success "test_get_arg passed."
  else
    print_error "test_get_arg failed. Expected: ${expected}, Got: ${result}"
    FAILED_TESTS+=("test_get_arg")
  fi
}

# Test set_arg
function test_set_arg() {
  local json='{"args":[{"key":"arg1","value":"value1"}]}'
  local key="arg1"
  local value="new_value"
  local expected='{"args":[{"key":"arg1","value":"new_value"}]}'
  print_info "Running test: test_set_arg"

  local result
  result=$(set_arg "${json}" "${key}" "${value}")

  if [[ "${result}" == "${expected}" ]]; then
    print_success "test_set_arg passed."
  else
    print_error "test_set_arg failed. Expected: ${expected}, Got: ${result}"
    FAILED_TESTS+=("test_set_arg")
  fi
}

# Test delete_arg
function test_delete_arg() {
  local json='{"args":[{"key":"arg1","value":"value1"}]}'
  local key="arg1"
  local expected='{"args":[]}'
  print_info "Running test: test_delete_arg"

  local result
  result=$(delete_arg "${json}" "${key}")

  if [[ "${result}" == "${expected}" ]]; then
    print_success "test_delete_arg passed."
  else
    print_error "test_delete_arg failed. Expected: ${expected}, Got: ${result}"
    FAILED_TESTS+=("test_delete_arg")
  fi
}

# Test check_args
function test_check_args() {
  local json='{"args":[{"key":"arg1","value":"value1"}]}'
  print_info "Running test: test_check_args"

  if check_args "${json}" "arg1"; then
    print_success "test_check_args passed."
  else
    print_error "test_check_args failed."
    FAILED_TESTS+=("test_check_args")
  fi
}

# Test print_args
function test_print_args() {
  local json='{"args":[{"key":"arg1","value":"value1"}]}'
  print_info "Running test: test_print_args"

  local result
  result=$(print_args "${json}")

  if [[ "${result}" == "${json}" ]]; then
    print_success "test_print_args passed."
  else
    print_error "test_print_args failed. Expected: ${json}, Got: ${result}"
    FAILED_TESTS+=("test_print_args")
  fi
}

# Test pretty_print_args
function test_pretty_print_args() {
  local json='{"args":[{"key":"arg1","value":"value1"}]}'
  local expected=$(echo "${json}" | jq)
  print_info "Running test: test_pretty_print_args"

  local result
  result=$(pretty_print_args "${json}")

  if [[ "${result}" == "${expected}" ]]; then
    print_success "test_pretty_print_args passed."
  else
    print_error "test_pretty_print_args failed. Expected: ${expected}, Got: ${result}"
    FAILED_TESTS+=("test_pretty_print_args")
  fi
}

# Run all tests
function run_tests() {
  print_info "Starting unit tests for args.sh"

  test_init_args
  test_add_arg
  test_get_arg
  test_set_arg
  test_delete_arg
  test_check_args
  test_print_args
  test_pretty_print_args

  if [[ ${#FAILED_TESTS[@]} -eq 0 ]]; then
    print_success "All tests passed successfully!"
  else
    print_error "The following tests failed: ${FAILED_TESTS[*]}"
    exit 1
  fi
}

run_tests