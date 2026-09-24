# ComputerScience

ComputerScience is an experimental architectural-planning project between semantic specification and concrete execution. It is intended to help choose and compose implementations using target facts, calculations, measurements, constraints, and programmer preferences, then leave behind an explicit plan that ordinary target-specific compilation can follow.

This repository currently contains two related kinds of material:

- top-level subject and hardware references, presently including Android input, GPU, floating-point semantics, analytic-combinatorics, and electronics; CPU/ISA catalogs follow the same top-level reference convention when added;
- the nested [`architecture-search/`](architecture-search/) area for the experimental planner, its evidence model, and end-to-end examples.

The floating-point contract in [`floating-point/semantics.md`](floating-point/semantics.md) keeps F16/F32 value width separate from software/hardware arithmetic, Arm `soft`/`softfp`/hard calling convention, scalar/vector execution, and GPU precision. The same record is intended to drive the Idris/Idriç GLSL backend and its CPU/framebuffer oracles.

The top-level catalogs are intentionally not being moved merely to make the tree look uniform. Several were requested as independently browsable references. The `architecture-search/` directory is the boundary for the planner experiment.

## Current status

The repository is currently in the design, cataloging, and evidence-gathering stage. Everything on `main` is prose, and this branch adds prose scaffolding only. There is no executable component schema, observation store, verifier, SURFER selection trace, planner, constraint solver, autotuner, or ComputerScience compiler here. Catalog entries and proposed directory structure do not count as implementations.

Relevant implementations exist in neighboring repositories: the [Idriç compiler](https://github.com/isomorphisms/Idric), the [Idris-to-GLSL ES backend](https://github.com/isomorphisms/idris-shader-backend), and the existing [CPU-only Java SURFER app](https://github.com/isomorphisms/algebraic-variety-explorer-mobile). They are implementation evidence and possible lowering machinery, not an implemented ComputerScience planner.

The first intended vertical slice is SURFER. IB/eyebrowser is the committed second slice and will be developed on a separate branch so it can test process composition, renderer choice, data movement, and resource policy without diluting the SURFER lowering trace. Field Mouse remains a possible later trial until its interface and acceptance criteria are specified.

## Source discipline

- Separate semantic operations from algorithm variants and platform primitives.
- Keep provenance, assumptions, uncertainty, target/ABI facts, and failure observations.
- Do not infer an installed ABI or usable instruction set from a processor name alone.
- Treat LLM output as a proposal unless it is supported by checkable evidence.
- Record selected and rejected alternatives so a result can be inspected and replayed.
- Prefer small programs with explicit inputs and outputs; use shell or Grease composition unless evidence justifies fusion or a long-lived process.

The reconciled design rationale is in [`notes/architectural-compilation.md`](notes/architectural-compilation.md).


A complementary design note, [Numeric types are maps, not just bit layouts](notes/numeric-types-as-maps.md), records the Cortex-A55/FP8 lesson that choosing a carrier does not determine conversion, arithmetic, accumulation, or lowering maps, and that the planner should enumerate and measure implementation tradeoffs rather than hand low-level mechanism selection back to the programmer.
