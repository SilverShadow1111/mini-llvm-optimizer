cmake_minimum_required(VERSION 3.20)
project(MiniLLVMOptimizer LANGUAGES CXX)

find_package(LLVM REQUIRED CONFIG)

add_library(AlgebraicSimplify MODULE
    src/AlgebraicSimplify.cpp
)

target_include_directories(AlgebraicSimplify
    PRIVATE ${LLVM_INCLUDE_DIRS}
)

target_compile_definitions(AlgebraicSimplify
    PRIVATE ${LLVM_DEFINITIONS}
)

target_compile_features(AlgebraicSimplify
    PRIVATE cxx_std_17
)

set_target_properties(AlgebraicSimplify PROPERTIES
    PREFIX ""
)
