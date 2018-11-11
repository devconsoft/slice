#!/bin/bash

ASSERT_LAST_OUTPUT=

# start test
stest() {
    local testname=$1
    echo -n "${testname}: "
}

# end test
etest() {
    echo "pass"
}

# fail test
ftest() {
    echo "FAIL"
}

# $1 expression
# $2 exit code
# $3 expected exit code
print_outcome() {
    local expression=$1
    local exit_code=$2
    local expected_exit_code=$3
    echo ""
    echo "----------------------"
    echo "Expression: '${expression}'"
    echo "exit code (expected): ${exit_code} (${expected_exit_code})"
    echo "with output:"
    echo "${ASSERT_LAST_OUTPUT}"
    echo "----------------------"
}

# $1 match
print_match() {
    local match=$1
    echo ""
    echo "----------------------"
    echo "Match: ${match}"
    echo "Outout:"
    echo "${ASSERT_LAST_OUTPUT}"
    echo "----------------------"
}

# $1 expression
# $2 expected exit code
assert_expr() {
    local expression="$1"
    local expected_exit_code=${2:-0}
    local exit_code=0
    ASSERT_LAST_OUTPUT=$(eval "${expression}") || exit_code=$?
    if [ "${exit_code}" != "${expected_exit_code}" ]; then
        print_outcome "${expression}" "${exit_code}" "${expected_exit_code}"
        ftest
        return ${exit_code}
    elif [ -n "${TEST_DEBUG:-}" ]; then
        print_outcome "${expression}" "${exit_code}" "${expected_exit_code}"
    fi

    return 0
}

# $1 match
# $2 expression
# $3 expected exit code =0
assert_in_output_expr() {
    local match="$1"
    local expression="$2"
    local expected_exit_code=${3:-0}

    assert_expr "${expression}" "${expected_exit_code}"

    if [[ ! "${ASSERT_LAST_OUTPUT}" =~ $match ]]; then
        print_match "${match}"
        return 1
    elif [ -n "${TEST_DEBUG:-}" ]; then
        print_match "${match}"
    fi
    return 0
}

# $1 first
# $2 second
assert_equal() {
    if [ -n "${TEST_DEBUG:-}" ]; then
        diff -y <(echo "$1") <(echo "$2")
    else
        diff -u <(echo "$1") <(echo "$2")
    fi
}

# $1 expected_output
# $2 expression
# $3 expected exit code
assert_equal_output_expr() {
    local expected_output="$1"
    local expression="$2"
    local expected_exit_code=${3:-0}

    assert_expr "${expression}" "${expected_exit_code}"
    assert_equal "${expected_output}" "${ASSERT_LAST_OUTPUT}"
}


self_test() {
    stest "Test framework self-tests"
    test "assert_expr 'true'"
    assert_expr 'assert_expr true'
    ! assert_expr 'false' > /dev/null || return 1
    assert_in_output_expr 'FOO' 'echo FOO'
    ! assert_in_output_expr 'FOO' 'false' > /dev/null || return 1

    IFS='' read -r -d '' ml1 <<'EOF' || true
line 1
line 2
EOF

    IFS='' read -r -d '' ml2 <<'EOF' || true
line 1
line 2
line 3
EOF

    assert_equal "${ml1}" "${ml1}"
    ! assert_equal "${ml1} "${ml2} >> /dev/null || return 1
    assert_equal_output_expr "FOO" "echo FOO"
    ! assert_equal_output_expr "FOO" "echo BAR" >> /dev/null || return 1
    etest
}
