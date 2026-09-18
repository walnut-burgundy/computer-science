# Idris compiler-backend observations

This directory is the ComputerScience-side log for AICI's deterministic
compiler-backend probes.

The split is deliberate:

- AICI owns the conventional, repeatable measurement code and the probe matrices.
- ComputerScience records the initial state, remembers the last state it saw,
  notices changes in either the observation surface or watched revisions, and
  asks an LLM to interpret a change packet.
- LLM interpretation is commentary over checkable evidence. It does not replace
  the TSV observations and it does not turn an observed difference into a build
  verdict.

`initial-observations.tsv` and `initial-revisions.tsv` are immutable historical
baselines from 2026-08-26. `last-seen-observations.tsv` and
`last-seen-revisions.tsv` begin at that historical state and are advanced by the
watcher only after it logs a change. New FP16 and consumer observations are not
backfilled into the initial baseline.

The watcher currently follows the active development refs:

- AICI `compiler-backend-observations`, including the general backend,
  FP16/PowerVR, and downstream FP16-consumer matrices;
- `idric-arm-thumb:idric-ir-first-slice` while PR #1 is the active
  implementation line;
- `idris-arm-backend:main`;
- `idris-shader-backend:main`, the merged whole-shader F16 compiler
  line;
- `algebraic-variety-explorer-mobile:dogfood/idris-shader-f16`, an independent
  downstream algebraic-surface compiler consumer.

When those active lines merge, move the watched refs to `main` at the same time
rather than silently continuing to watch abandoned feature branches.

The FP16 rows intentionally separate different strengths of evidence. The
selectable whole-shader mode is now executable: a compiler directive selects
F16/F32, the checked diagnostic IR reports the selected F16/F32 semantic names,
and emission selects mediump/highp. That is distinct from still-open per-value
width in the underlying typed IR, explicit F16/F32 conversions, source-level
F16 types, and real PowerVR framebuffer evidence.

The Algebraic Variety Explorer consumer adds another evidence level: it pins the
exact shader backend, compiles the bounded Surfer root-search shader as both F16
and F32, validates the generated fragments, rejects F64, and retains the
artifacts. This is stronger than a literal source marker but remains a compiler
consumer gate, not proof of exact binary16 execution on the GPU.

## LLM pass

The workflow builds a deterministic packet containing old and new TSVs,
revision changes, and source diffs for changed backend and consumer refs. It
then attempts a non-interactive GitHub Copilot CLI pass and puts that
interpretation in a GitHub issue together with the raw diffs.

The interpretation prompt treats FP16 as a first-class semantic target and
explicitly distinguishes whole-shader selection, per-value typed IR, downstream
compile validation, and real-device numerical evidence.

For a personal repository, the Copilot CLI may require a repository secret
named `COPILOT_GITHUB_TOKEN` containing an appropriately scoped fine-grained
token. If that credential is absent or inference fails, the watcher still logs
the deterministic change packet and explicitly records that no LLM
interpretation was produced. Observation never depends on the LLM succeeding.

The watcher intentionally consumes AICI's `compiler_backends/probe.py` rather
than keeping a second implementation.
