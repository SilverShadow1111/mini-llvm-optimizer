# Mini LLVM Optimizer

A lightweight LLVM optimization pass implemented in C++ using the LLVM 18 New Pass Manager.

This project explores compiler optimization techniques by implementing algebraic simplification rules directly on LLVM Intermediate Representation (IR).

## Features

The pass currently supports five integer algebraic simplification rules:

| Rule | Transformation |
|---|---|
| Addition | `x + 0 → x` |
| Addition | `0 + x → x` |
| Multiplication | `x * 1 → x` |
| Multiplication | `1 * x → x` |
| Subtraction | `x - 0 → x` |

The implementation traverses LLVM functions and basic blocks, identifies matching binary operations, replaces redundant instruction uses, and removes unnecessary instructions.

## Requirements

- LLVM 18
- Clang 18
- CMake
- Ninja
- C++17-compatible compiler
- Linux (tested on Ubuntu)

## Build

```bash
cmake -S . -B build -G Ninja \
  -DCMAKE_CXX_COMPILER=/usr/bin/clang++-18 \
  -DLLVM_DIR=/usr/lib/llvm-18/cmake

cmake --build build
```

This generates the LLVM pass plugin:

```text
build/AlgebraicSimplify.so
```

## Usage

Run the pass on an LLVM IR file:

```bash
opt-18 \
  -load-pass-plugin=build/AlgebraicSimplify.so \
  -passes=algebraic-simplify \
  -S tests/multiply.ll \
  -o build/optimized.ll
```

### Example

Before optimization:

```llvm
define i32 @test_mul(i32 %x) {
entry:
  %a = mul i32 %x, 1
  %b = mul i32 1, %a
  %c = add i32 %b, 0
  ret i32 %c
}
```

After optimization:

```llvm
define i32 @test_mul(i32 %x) {
entry:
  ret i32 %x
}
```

## Testing

The project includes positive and negative tests to check that supported algebraic identities are simplified while non-matching operations are preserved.

Run all tests:

```bash
./scripts/run_tests.sh
```

The test script also invokes LLVM's IR verifier.

## Implementation

The optimization pass uses LLVM's New Pass Manager and operates at the function level.

Key LLVM APIs include:

- `BinaryOperator` for identifying arithmetic instructions
- `ConstantInt` for inspecting integer constants
- `replaceAllUsesWith()` for updating instruction uses
- `eraseFromParent()` for removing redundant instructions
- `PreservedAnalyses` for reporting whether the IR was modified

## Limitations

This is an educational compiler project rather than a production-ready optimizer.

It currently handles a small set of integer algebraic identities and uses a lightweight Bash-based test suite. Future improvements may include LLVM FileCheck tests, additional optimization rules, and more comprehensive correctness testing.

## Future Improvements

- Add LLVM `lit` and `FileCheck` tests
- Extend algebraic simplification patterns
- Explore compiler analysis passes and use-def chains
- Investigate optimization considerations for GPU-oriented workloads