# ComputerScience

ComputerScience is an experimental architectural-planning project between semantic specification and concrete execution. It is intended to help choose and compose implementations using target facts, calculations, measurements, constraints, and programmer preferences, then leave behind an explicit plan that ordinary target-specific compilation can follow.

This repository currently contains two related kinds of material:

- top-level subject and hardware references, presently including Android input, GPU, analytic-combinatorics, and electronics; CPU/ISA catalogs follow the same top-level reference convention when added;
- the nested [`architecture-search/`](architecture-search/) area for the experimental planner, its evidence model, and end-to-end examples.

The top-level catalogs are intentionally not being moved merely to make the tree look uniform. Several were requested as independently browsable references. The `architecture-search/` directory is the boundary for the planner experiment.

## Current status

The repository is still primarily in the design, cataloging, and evidence-gathering stage. The first small executable observation path is now defined under [`compiler-backends/`](compiler-backends/) with a scheduled watcher in `.github/workflows/`: it consumes AICI's deterministic compiler-backend probes, preserves an initial and last-seen state, and logs changed evidence for later interpretation. This is an observation mechanism, not an implemented component schema, verifier, SURFER selection trace, planner, constraint solver, autotuner, or ComputerScience compiler.

Relevant implementations exist in neighboring repositories: the [Idriç compiler](https://github.com/isomorphisms/Idric), the [Idris-to-GLSL ES backend](https://github.com/isomorphisms/idris-shader-backend), and the existing [CPU-only Java SURFER app](https://github.com/isomorphismes/algebraic-variety-explorer-mobile). They are implementation evidence and possible lowering machinery, not an implemented ComputerScience planner.

The first intended vertical slice is SURFER. IB/eyebrowser is the committed second slice and will be developed on a separate branch so it can test process composition, renderer choice, data movement, and resource policy without diluting the SURFER lowering trace. Field Mouse remains a possible later trial until its interface and acceptance criteria are specified.

## Source discipline

- Separate semantic operations from algorithm variants and platform primitives.
- Keep provenance, assumptions, uncertainty, target/ABI facts, and failure observations.
- Do not infer an installed ABI or usable instruction set from a processor name alone.
- Treat LLM output as a proposal unless it is supported by checkable evidence.
- Record selected and rejected alternatives so a result can be inspected and replayed.
- Prefer small programs with explicit inputs and outputs; use shell or Grease composition unless evidence justifies fusion or a long-lived process.

The reconciled design rationale is in [`notes/architectural-compilation.md`](notes/architectural-compilation.md).
