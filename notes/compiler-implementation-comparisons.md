# Compiler implementation comparison reference

The ICK repository has an `inspiration` branch that collects exact upstream
compiler source references and comparative notes. ComputerScience should treat
that material as research evidence, not as an architecture decision.

Reference:

- https://github.com/dilapidated-shed/ick/tree/inspiration/inspiration
- `gcc-contrast-notes.md` — public discussion and project documentation
  contrasting GCC with Clang/LLVM, TinyCC, chibicc, cproc/QBE, lacc, 8cc,
  cparser/libFirm, CompCert, PCC, slimcc, and c4.
- `kernel-construct-corpus.md` — Linux-kernel C constructs matched to
  constructs already used in ICK/Wegert/Pauli.
- `first-six-traces.md` — paired production-source traces for wrapper types,
  small inline operations, union/designated representation views, layout
  contracts, mask/shift extraction, and memory-copy paths.
- `fixtures/` — secondary reduced probes tied back to those exact source
  pairs.

## Why this belongs in ComputerScience

The comparison is useful when architecture search has to choose how much
compiler machinery a target path actually needs.

For CPU targets, especially A32/T32 and other constrained machines, revisit:

- cost of a large multi-stage optimizer versus direct code generation;
- retargeting seams and target-description locality;
- ABI handling for small wrapper types and aggregates;
- mask/shift lowering for compact numeric formats;
- ordinary call versus builtin versus explicit-IR treatment of block copies;
- C inline/linkage semantics versus optimizer-time inlining.

For GPU work, revisit:

- source-semantic representation versus backend IR representation;
- small stable frontend/backend boundaries such as cproc/QBE;
- explicit operations such as libFirm `CopyB` or CompCert's named memcpy
  effect instead of immediately dissolving everything into lower-level code;
- explicit refusal boundaries, which small compilers make especially visible.

## Update rule

Refresh this pointer when the ICK comparison gains executable results,
additional compiler sources, or materially different conclusions.

Do not copy a compiler architecture merely because it looks smaller or cleaner.
Record the target requirement first, then use the comparison to ask which
representation, optimization, and lowering layers earn their cost.
