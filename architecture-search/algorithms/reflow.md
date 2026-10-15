# Reflow: one verb, two executable ways

Status: **executable Idriç candidate exists in [IB PR #157](https://github.com/isomorphisms/ib/pull/157); not integrated into the native reader and not yet architecture-qualified.** This is an algorithm/selection record, not the general ComputerScience planner.

This is a concrete instance of [adverbs as manner and constraints](https://github.com/walnut-burgundy/computer-science/issues/71). The operation is simply `reflow`; the selected mechanism is revealed by descent.

```text
reflow
  └─ how?
      ├─ promptly → greedy reflow
      └─ evenly   → minimum-squared-slack reflow
```

## Contract of the first experiment

Input: an ordered list of unbreakable text segments, a positive available width, a deterministic width-measuring function, and a manner request. A single ordinary space is inserted between adjacent segments displayed on the same line. The caller, not this experiment, owns source decoding, semantic paragraph boundaries, segment construction, link/source offsets, font shaping, and the width function.

Output: lines with the segments in their original order. Neither way drops or clips segments or inserts a break *inside* a segment. An individually overwide segment stays intact on its own line, requiring a later display policy for overflow. A zero width is rejected.

Acceptable differences: where between-segment breaks occur, the number of lines, time and memory. Not acceptable: lost content, changed segment order, invented source text, changed source identity, or hidden clipping. Different spacing and paragraph boundaries are not silently made equivalent: this experiment explicitly treats source segments as atomic and puts one display space between them.

## Executed by one selector

`IB.Reflow.reflow` receives a `ReflowRequirements` value, a width-measuring function and the segments. `select_reflow` maps:

| Requested manner | Selected way | Tradeoff |
| --- | --- | --- |
| `promptly` | `reflow_greedily` | Forward scan; one active line, stream-friendly. Earlier breaks can leave ragged lines. |
| `evenly` | `reflow_balanced` | Paragraph-wide suffix dynamic programming; minimizes sum of squared unused widths, including last line. Quadratic candidate space and greater retained state, with additional work from text concatenation. |

This selector implements an explicit manner decision. It is **not** a claim that a particular method wins on the MIRO A1 ARM32, MIRO C67 ARM64, Linux x86-64, or macOS. No target-specific performance selection is justified without actual measurements. The shared operation does not name a terminal language or compiler.

The Idriç modules are:

- [`src/IB/Reflow.idric`](https://github.com/isomorphisms/ib/blob/feature/reflow-two-ways/src/IB/Reflow.idric) — top-level verb and selector
- [`src/IB/Reflow/Greedy.idric`](https://github.com/isomorphisms/ib/blob/feature/reflow-two-ways/src/IB/Reflow/Greedy.idric)
- [`src/IB/Reflow/Balanced.idric`](https://github.com/isomorphisms/ib/blob/feature/reflow-two-ways/src/IB/Reflow/Balanced.idric)
- [`src/InformationSmoke.idric`](https://github.com/isomorphisms/ib/blob/feature/reflow-two-ways/src/InformationSmoke.idric) — runs both paths and compares observable results

## First comparison / refusal cases

At a width of eight character counts, segments `aa bb cc dd eeeeee` produce:

```text
promptly:
  aa bb cc
  dd
  eeeeee

evenly:
  aa bb
  cc dd
  eeeeee
```

The algorithmic difference is intentional: **both preserve the same segments and order**. The first candidate's total squared slack is 40; the second's is 22. These are mathematical costs under this simple *test metric*, not measured run times. The test also checks that a single segment longer than the width remains complete, an empty paragraph stays empty, and a zero-width request is rejected.

## Next architecture-search question, not a fabricated answer

Before automatic selection by target, record on each actual target: program/compiler revision, width metric (character count versus native pixel shaping), paragraph length distribution, cold first-paint latency, median/99th percentile, peak resident memory, power if obtainable, and any unacceptable visual output. Compare the two ways on identical inputs and metrics; retain rejected candidates and reasons. An `evenly` hard requirement must not silently fall back to `promptly` solely because the target is slow. If a preference permits degradation, distinguish that explicitly.

Native reflow still needs semantic source/link offsets and glyph-shaped pixel widths. Unicode bidirectional text, combining marks, unbreakable words wider than the viewport, and HTML structure require separate explicit acceptance. This record does not promote the character-count smoke case into those claims.
