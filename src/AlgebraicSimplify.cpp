#include "llvm/IR/PassManager.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Constants.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"

using namespace llvm;

namespace {

// Custom LLVM function pass
struct AlgebraicSimplifyPass
    : public PassInfoMixin<AlgebraicSimplifyPass> {

    PreservedAnalyses run(
        Function &F,
        FunctionAnalysisManager &
    ) {
        bool Changed = false;

        // Iterate over basic blocks
        for (BasicBlock &BB : F) {

            // Iterate safely while removing instructions
            for (auto It = BB.begin(); It != BB.end();) {

                Instruction &I = *It++;

                // Skip non-binary instructions
                auto *BO = dyn_cast<BinaryOperator>(&I);

                if (!BO)
                    continue;

                // Get operands
                Value *LHS = BO->getOperand(0);
                Value *RHS = BO->getOperand(1);

                // Rules 1-2: x + 0 -> x, 0 + x -> x
                if (BO->getOpcode() == Instruction::Add) {

                    if (matchZero(RHS)) {
                        BO->replaceAllUsesWith(LHS);
                        BO->eraseFromParent();
                        Changed = true;
                    }
                    else if (matchZero(LHS)) {
                        BO->replaceAllUsesWith(RHS);
                        BO->eraseFromParent();
                        Changed = true;
                    }
                }

                // Rules 3-4: x * 1 -> x, 1 * x -> x
                else if (BO->getOpcode() == Instruction::Mul) {

                    if (matchOne(RHS)) {
                        BO->replaceAllUsesWith(LHS);
                        BO->eraseFromParent();
                        Changed = true;
                    }
                    else if (matchOne(LHS)) {
                        BO->replaceAllUsesWith(RHS);
                        BO->eraseFromParent();
                        Changed = true;
                    }
                }

                // Rule 5: x - 0 -> x
                else if (BO->getOpcode() == Instruction::Sub) {

                    // Only simplify when the RHS is zero
                    if (matchZero(RHS)) {
                        BO->replaceAllUsesWith(LHS);
                        BO->eraseFromParent();
                        Changed = true;
                    }
                }
            }
        }

        // Invalidate analyses if the IR was modified
        return Changed
            ? PreservedAnalyses::none()
            : PreservedAnalyses::all();
    }

private:

    // Check for integer constant zero
    static bool matchZero(Value *V) {
        auto *CI = dyn_cast<ConstantInt>(V);
        return CI && CI->isZero();
    }

    // Check for integer constant one
    static bool matchOne(Value *V) {
        auto *CI = dyn_cast<ConstantInt>(V);
        return CI && CI->isOne();
    }
};

} // namespace

// LLVM New Pass Manager plugin entry point
extern "C" LLVM_ATTRIBUTE_WEAK
PassPluginLibraryInfo llvmGetPassPluginInfo() {

    return {
        LLVM_PLUGIN_API_VERSION,
        "AlgebraicSimplify",
        LLVM_VERSION_STRING,

        [](PassBuilder &PB) {

            PB.registerPipelineParsingCallback(
                [](StringRef Name,
                   FunctionPassManager &FPM,
                   ArrayRef<PassBuilder::PipelineElement>) {

                    if (Name == "algebraic-simplify") {
                        FPM.addPass(AlgebraicSimplifyPass());
                        return true;
                    }

                    return false;
                }
            );
        }
    };
}
