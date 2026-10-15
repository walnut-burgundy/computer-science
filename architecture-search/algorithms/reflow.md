# Reflow: a semantic operation with a portfolio of realizations

**Status, 2026-10-15:** Sources and smoke cases are on draft [IB PR #157, *Implement two selectable Idriç reflow strategies*](https://github.com/isomorphisms/ib/pull/157). That PR has been expanded beyond its initial two strategies. The pinned Idriç compiler/runtime and physical Android-reader acceptance are **NOT_VERIFIED** for its latest head; source presence is not an execution claim.

The top-level verb remains **`reflow`**. Adverbs describe manner; the selector chooses and invokes one method. This is a concrete companion to [adverbs issue #71](https://github.com/walnut-burgundy/computer-science/issues/71).

```text
reflow
  └── how?
      ├── promptly                 → greedy
      ├── streamingly              → streaming greedy
      ├── evenly                   → squared-slack optimal DP
      ├── minimizing_raggedness    → cubic-slack optimal DP
      ├── ignoring_final_line      → last-line-free optimal DP
      ├── minimizing_worst_gap     → minimax-slack optimal DP
      ├── without_extra_lines     → threshold balancing
      └── typographically         → space-glue Knuth–Plass subset
```

The `reflow` API is in [`src/IB/Reflow.idric`](https://github.com/isomorphisms/ib/blob/feature/reflow-two-ways/src/IB/Reflow.idric). The modes named above **dispatch to implementations** rather than merely appearing in a proposed catalog. Width measurement is an injected function; test metrics count characters. Native glyph/pixel width and actual justification have **not** been qualified.

## Implemented candidate ways and tradeoffs

| Way | Mechanism | Tradeoff and admissibility |
| --- | --- | --- |
| **Greedy** | Scan segments in order, put each on the current line if it fits | Small working set; no paragraph-wide visual optimization |
| **Streaming greedy** | `begin_stream`, `feed_chunk`, `finish_stream`, `end_paragraph`; partial words survive transport chunks | Emits full lines before end-of-document; uses whitespace delimitation; no paragraph-wide optimization |
| **Squared-slack optimal** | Suffix DP minimizing sum of squared unused widths **including** final line | Tries O(n²) break candidates; may prefer extra lines or different breaks |
| **Cubic raggedness** | Suffix DP minimizing cubic unused width | Stronger penalty for very short lines; more computational work |
| **Final-line-free optimal** | Suffix DP minimizing squared slack excluding the final line | Often preferable for ordinary left-ragged paragraphs; can leave a very short last line |
| **Minimax** | Suffix DP minimizing the maximum unused width | Protects against one very short line, possibly at the expense of total whitespace |
| **Threshold balance** | Find greedy's minimum number of lines, then narrow effective width while preserving that count | Fast working set, potentially O(width × n) scans; heuristic, not globally optimal |
| **Knuth–Plass, space-only subset** | Word boxes, stretchable/shrinkable space glues, cubic badness, line/fitness demerits, suffix DP keyed by previous fitness | Annotated spacing plan; O(n² × fitness states). No dictionary hyphenation, discretionary penalties, or proof of full TeX parity; plain-text projection does not justify spaces visually |

**Incremental reflow** is a ninth, **orthogonal** available mechanism: [`IB.Reflow.Incremental`](https://github.com/isomorphisms/ib/blob/feature/reflow-two-ways/src/IB/Reflow/Incremental.idric) reuses a paragraph's derived layout only when source segments, width, chosen manner and font/measurement key match. A changed paragraph, viewport width, or measurement key forces recomputation. This is a revision/cache strategy, not an interchangeable objective for the stateless batch signature.

## Shared contract, source versus display

The basic batch operation accepts an ordered list of *unbreakable* text segments, positive width and deterministic measurement. It joins neighboring segments on a line with one ordinary display space; every original segment remains in source order; it never clips or silently splits one. A singleton overwide segment can occupy an overwide line, which a later presentation policy must handle.

For streaming, chunk boundaries are **not word boundaries**. `feed_chunk` retains the unfinished word, emits only completed lines, and uses ASCII whitespace as temporary segmentation. `end_paragraph` flushes semantically. Exact decoded source and link spans remain IB-owned; a rendered line is not reparsed as the source of truth.

The Knuth–Plass subset additionally exposes `JustifiedLine` with a `SpaceAdjustment` fraction. Its top-level `reflow` projection retains only line breaks. A native backend that actually stretches/shrinks glues must consume the annotated plan; showing a line string does not establish typographic justification.

Different break locations and performance **are permitted differences**. Dropping/reordering text, breaking inside a protected segment, inventing source bytes, changing source identity, or silently weakening a hard constraint are not.

## Behavioral examples

At a width of eight character counts, the segments `aa bb cc dd eeeeee` produce:

```text
promptly / streamingly:
  aa bb cc
  dd
  eeeeee

evenly:
  aa bb
  cc dd
  eeeeee
```

These are different correct layouts with the same source segments. In [`ReflowSmoke.idric`](https://github.com/isomorphisms/ib/blob/feature/reflow-two-ways/src/ReflowSmoke.idric), a second seven-segment example discriminates squared, cubic, final-line-free and minimax objectives. Streaming checks partial-word chunk boundaries and early emission. Incremental checks cache hits and edit/width/metric-key invalidation. No device performance number is inferred from those functional cases.

## Other known techniques: preserve as research, not invented implementations

| Technique | How it differs | Present availability |
| --- | --- | --- |
| ICU/Unicode UAX #14 break opportunities | Word, punctuation and script-specific legal breaks | Needs a verified segmentation adapter; not replaced by ASCII whitespace splitting |
| Knuth–Liang dictionary hyphenation | Inserts discretionary hyphen positions subject to language/dictionary | Not implemented in the current segment-only input type |
| Full TeX penalties and fitness | Explicit discretionary break nodes, hyphen penalties, consecutive flagged breaks, widow/orphan control | Restricted space-glue implementation above does **not** supply all these properties |
| SIMD-assisted UTF-8/break scanning | Faster target-specific segmentation; not another paragraph objective | No qualified ICK ARM32/ARM64 or x86 implementation or benchmark yet |
| Incremental changed-range/viewport reflow | Preserve unaffected line boxes within a paragraph | Current cache is per entire paragraph; range-level version requires stable source/glyph offsets |
| Emergency cluster/character wrapping | Changes which units may split, not merely the break optimizer | Requires an explicit representation/contract for grapheme clusters and source offsets |
| Full paragraph justification | Turns line breaks and spacing adjustment fractions into actual glyph positions | Needs native backend use of spacing plans |

These entries are known choices but **not runnable options** in the selector. Do not quietly route them through greedy reflow and label them implemented.

## Evidence to gather before hardware-specific auto-selection

For A1 ARM32, C67 ARM64, Linux x86-64 and macOS targets, pin executable/toolchain/source revisions and record identical inputs, requested adverbs, results, measurement function, source/decoded offset checks, cold-to-first-line time, total time, peak memory and failed constraints. A structural advantage is a hypothesis until measured. Selection by device family without evidence must not silently override a programmer's required manner.
