#!/usr/bin/env bash
set -euo pipefail

# Change to the project root
cd "$(dirname "$0")/.."

PLUGIN="build/AlgebraicSimplify.so"

# Check if the plugin exists
if [[ ! -f "$PLUGIN" ]]; then
    echo "ERROR: Plugin not found: $PLUGIN"
    echo "Please run: cmake --build build"
    exit 1
fi

# Create the test output directory
mkdir -p build/test-results

# Run the pass and verify the resulting IR
run_pass() {
    local input="$1"
    local output="$2"

    opt-18 \
        -load-pass-plugin="$PLUGIN" \
        -passes="algebraic-simplify,verify" \
        -S "$input" \
        -o "$output"
}

# Check that the file contains the expected text
assert_contains() {
    local file="$1"
    local pattern="$2"

    if ! grep -Fq -- "$pattern" "$file"; then
        echo "FAIL: Expected text not found: $pattern"
        echo "File: $file"
        exit 1
    fi
}

# Check that the file does not contain the given text
assert_not_contains() {
    local file="$1"
    local pattern="$2"

    if grep -Fq -- "$pattern" "$file"; then
        echo "FAIL: Unexpected text found: $pattern"
        echo "File: $file"
        exit 1
    fi
}

echo "======================================"
echo " Running AlgebraicSimplify Tests"
echo "======================================"

# Test 1: Addition simplification
echo "[1/4] Testing addition..."

run_pass \
    tests/basic.ll \
    build/test-results/basic.ll

assert_contains \
    build/test-results/basic.ll \
    "ret i32 %x"

assert_not_contains \
    build/test-results/basic.ll \
    " = add i32 "

echo "PASS: Addition simplification"

# Test 2: Multiplication simplification
echo "[2/4] Testing multiplication..."

run_pass \
    tests/multiply.ll \
    build/test-results/multiply.ll

assert_contains \
    build/test-results/multiply.ll \
    "ret i32 %x"

assert_not_contains \
    build/test-results/multiply.ll \
    " = mul i32 "

assert_not_contains \
    build/test-results/multiply.ll \
    " = add i32 "

echo "PASS: Multiplication simplification"

# Test 3: Negative tests
echo "[3/4] Testing non-optimizable operations..."

run_pass \
    tests/negative.ll \
    build/test-results/negative.ll

assert_contains \
    build/test-results/negative.ll \
    "add i32 %x, 5"

assert_contains \
    build/test-results/negative.ll \
    "mul i32 %a, 2"

echo "PASS: Non-optimizable operations preserved"

# Test 4: Subtraction simplification
echo "[4/4] Testing subtraction..."

run_pass \
    tests/subtract.ll \
    build/test-results/subtract.ll

# Extract the first function
sed -n '/define i32 @test_sub(/,/^}/p' \
    build/test-results/subtract.ll \
    > build/test-results/test_sub_only.ll

# Extract the second function
sed -n '/define i32 @test_keep_sub(/,/^}/p' \
    build/test-results/subtract.ll \
    > build/test-results/test_keep_sub_only.ll

# Verify that x - 0 is simplified
assert_contains \
    build/test-results/test_sub_only.ll \
    "ret i32 %x"

assert_not_contains \
    build/test-results/test_sub_only.ll \
    " = sub i32 "

assert_not_contains \
    build/test-results/test_sub_only.ll \
    " = add i32 "

# Verify that 0 - x is preserved
assert_contains \
    build/test-results/test_keep_sub_only.ll \
    "sub i32 0, %x"

echo "PASS: Subtraction simplification"

echo ""
echo "======================================"
echo " All tests passed!"
echo "======================================"
