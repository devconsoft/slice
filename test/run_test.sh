#!/bin/bash

set -o errexit -o nounset -o pipefail

TEST_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BIN_DIR="$(cd "${TEST_DIR}/../bin/" && pwd)"
SLICE="${BIN_DIR}/slice"

trap "cleanup" EXIT
cleanup() {
    local exit_code=$?
    if [ "${exit_code}" != "0" ]; then
        echo ""
        echo "TEST RUN FAILED"
    else
        echo "OK"
    fi
}

# shellcheck source=assert.sh
source "${TEST_DIR}/assert.sh"

cd "${TEST_DIR}"

self_test

test_help() {
    stest "Help"
    assert_in_output_expr "Usage" "${SLICE} --help"
    assert_in_output_expr "Usage" "${SLICE} -h"
    assert_equal "$(${SLICE} -h)" "$(${SLICE} --help)"
    etest
}

test_version() {
    stest "Version"
    assert_in_output_expr "Copyright DevConSoft" "${SLICE} --version"
    etest
}

test_catch_invalid_file() {
    stest "Catch invalid file"
    assert_in_output_expr "does not exist" "${SLICE} S E non_existing_file.txt" 4
    etest
}

test_full_file() {
    stest "slice full file"
    local expected_output; expected_output=$(<data/full.txt)
    local cmd="${SLICE} - - data/full.txt"
    assert_equal_output_expr "${expected_output}" "${cmd}"
    etest
}

test_slice_with_start_marker() {
    stest "slice with start marker"
    local expected_output; expected_output=$(<data/cd.txt)
    local cmd="${SLICE} c - data/full.txt"
    assert_equal_output_expr "${expected_output}" "${cmd}"
    etest
}

test_slice_with_start_marker() {
    stest "slice with end marker"
    local expected_output; expected_output=$(<data/ac.txt)
    local cmd="${SLICE} - c data/full.txt"
    assert_equal_output_expr "${expected_output}" "${cmd}"
    etest
}

test_start_marker_not_found() {
    stest "slice with start marker not in file gives exit code 1"
    local cmd="${SLICE} X c data/full.txt"
    assert_equal_output_expr "" "${cmd}" 1
    etest
}

test_end_marker_not_found() {
    stest "slice with end marker not in file gives exit code 1"
    local cmd="${SLICE} b X data/full.txt"
    assert_equal_output_expr "" "${cmd}" 1
    etest
}

test_slice_with_start_line() {
    stest "slice with start line"
    local expected_output; expected_output=$(<data/2c.txt)
    local cmd="${SLICE} 2 c data/full.txt"
    assert_equal_output_expr "${expected_output}" "${cmd}"
    etest
}

test_slice_with_end_line() {
    stest "slice with end line"
    local expected_output; expected_output=$(<data/b3.txt)
    local cmd="${SLICE} b 3 data/full.txt"
    assert_equal_output_expr "${expected_output}" "${cmd}"
    etest
}

test_read_from_stdin() {
    stest "read content from stdin"
    local expected_output; expected_output=$(<data/b3.txt)
    local cmd="cat data/full.txt | ${SLICE} b 3"
    assert_equal_output_expr "${expected_output}" "${cmd}"
    etest
}

test_print_line_numbers() {
    stest "print line numbers"
    local expected_output; expected_output=$(<data/b3ln.txt)
    local cmd="${SLICE} -n b 3 data/full.txt"
    assert_equal_output_expr "${expected_output}" "${cmd}"
    etest
}

test_before_context() {
    stest "before context"
    local expected_output; expected_output=$(<data/ac.txt)
    local cmd="${SLICE} -B 1 b 3 data/full.txt"
    assert_equal_output_expr "${expected_output}" "${cmd}"
    etest
}

test_after_context() {
    stest "after context"
    local expected_output; expected_output=$(<data/ac.txt)
    local cmd="${SLICE} -A 1 a b data/full.txt"
    assert_equal_output_expr "${expected_output}" "${cmd}"
    etest
}

test_context() {
    stest "context"
    local expected_output; expected_output=$(<data/full.txt)
    local cmd="${SLICE} -C 1 b c data/full.txt"
    assert_equal_output_expr "${expected_output}" "${cmd}"
    etest
}

test_first_end_marker_after_start() {
    stest "end marker is first occurance after start marker"
    local expected_output; expected_output=$(<data/trickyab.txt)
    local cmd="${SLICE} -B 2 -A 1 c a data/tricky.txt"
    assert_equal_output_expr "${expected_output}" "${cmd}"
    etest
}

test_same_marker() {
    stest "same start and end marker"
    local expected_output; expected_output="b"
    local cmd="${SLICE} b b data/full.txt"
    assert_equal_output_expr "${expected_output}" "${cmd}"
    etest
}

test_help
test_version
test_catch_invalid_file
test_full_file
test_slice_with_start_marker
test_start_marker_not_found
test_end_marker_not_found
test_slice_with_start_line
test_slice_with_end_line
test_read_from_stdin
test_print_line_numbers
test_before_context
test_after_context
test_first_end_marker_after_start
test_same_marker
