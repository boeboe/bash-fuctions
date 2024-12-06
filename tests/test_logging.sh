#!/usr/bin/env bash
# test_logging.sh - Unit tests for logging.sh
# shellcheck disable=SC1091

set -euo pipefail

# Source the logging library
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

# Test debug log
function test_print_debug() {
  local expected="[DEBUG] Debug message"
  print_info "Running test: test_print_debug"

  local result
  result=$(LOG_LEVEL=0 SILENT_MODE=false print_debug "Debug message" 2>&1)
  result=$(strip_output "${result}")

  if [[ "${result}" == "${expected}" ]]; then
    print_success "test_print_debug passed."
  else
    print_error "test_print_debug failed. Expected: ${expected}, Got: ${result}"
    FAILED_TESTS+=("test_print_debug")
  fi
}

# Test info log
function test_print_info() {
  local expected="[INFO] Info message"
  print_info "Running test: test_print_info"

  local result
  result=$(LOG_LEVEL=1 SILENT_MODE=false print_info "Info message" 2>&1)
  result=$(strip_output "${result}")

  if [[ "${result}" == "${expected}" ]]; then
    print_success "test_print_info passed."
  else
    print_error "test_print_info failed. Expected: ${expected}, Got: ${result}"
    FAILED_TESTS+=("test_print_info")
  fi
}

# Test warning log
function test_print_warning() {
  local expected="[WARNING] Warning message"
  print_info "Running test: test_print_warning"

  local result
  result=$(LOG_LEVEL=2 SILENT_MODE=false print_warning "Warning message" 2>&1)
  result=$(strip_output "${result}")

  if [[ "${result}" == "${expected}" ]]; then
    print_success "test_print_warning passed."
  else
    print_error "test_print_warning failed. Expected: ${expected}, Got: ${result}"
    FAILED_TESTS+=("test_print_warning")
  fi
}

# Test error log
function test_print_error() {
  local expected="[ERROR] Error message"
  print_info "Running test: test_print_error"

  local result
  result=$(LOG_LEVEL=3 SILENT_MODE=false print_error "Error message" 2>&1)
  result=$(strip_output "${result}")

  if [[ "${result}" == "${expected}" ]]; then
    print_success "test_print_error passed."
  else
    print_error "test_print_error failed. Expected: ${expected}, Got: ${result}"
    FAILED_TESTS+=("test_print_error")
  fi
}

# Test silent mode
function test_silent_mode() {
  print_info "Running test: test_silent_mode"

  local result
  result=$(LOG_LEVEL=3 SILENT_MODE=true print_error "Silent mode test" 2>&1 || true)

  if [[ -z "${result}" ]]; then
    print_success "test_silent_mode passed."
  else
    print_error "test_silent_mode failed. Expected no output, Got: ${result}"
    FAILED_TESTS+=("test_silent_mode")
  fi
}

# Run all tests
function run_tests() {
  print_info "Starting unit tests for logging.sh"

  test_print_debug
  test_print_info
  test_print_warning
  test_print_error
  test_silent_mode

  if [[ ${#FAILED_TESTS[@]} -eq 0 ]]; then
    print_success "All tests passed successfully!"
  else
    print_error "The following tests failed: ${FAILED_TESTS[*]}"
    exit 1
  fi
}

run_tests