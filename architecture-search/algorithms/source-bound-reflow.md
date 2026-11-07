# Source-bound line breaks (IB follow-on)

Implementation candidate: [isomorphisms/ib PR #159, *Preserve Unicode source offsets through selectable reflow*](https://github.com/isomorphisms/ib/pull/159), stacked on the eight-method [IB PR #157](https://github.com/isomorphisms/ib/pull/157).

**Status, 2026-10-17:** Idriç source and CI tests authored; source-bound host/runtime and physical-device results remain separately unverified until the exact candidate head is checked. This is not full Unicode line breaking.

## Why the previous word-list signature is insufficient

The original `reflow` algorithms receive already-extracted atomic word segments, then concatenate them with normalized display spaces. They demonstrably choose different valid line breaks, but cannot by themselves preserve a reader selection against exact decoded source in the presence of original spacing, control characters, soft hyphens, combining characters or multicodepoint emoji.

A native reading plan instead needs **exact positions between decoded source code points** and a distinct display projection:

```text
immutable decoded source
  ↓
break provider: source offsets + break kinds
  ↓
validate structural/mandatory break invariants
  ↓
reflow (adverb chooses line-break optimizer)
  ↓
line spans (source start/end) + derived visible text
  ↓
native glyph measurement/painting (separate acceptance)
```

Offsets in this experiment are `unpack Text` **code point indices**, not UTF-8 byte offsets, UTF-16 code units, grapheme cluster indices or rendered glyph positions. Conversion to a native adapter's coordinate system must be explicit and tested. A byte hash of the source must never be replaced by a hash of painted text.

## Break-source contract

`IB.Reflow.SourceBreaks` defines `SourceBreak` and `SourceLine`. Its locally authored `source_breaks` generates a **limited** set of allowed breaks after ordinary spaces, U+00AD soft hyphen, U+200B zero-width space and between adjacent Han ideographs in two declared scalar ranges. It recognizes mandatory CR, LF, CRLF (as one break), U+0085, U+2028 and U+2029; `SourceEnd` terminates non-hard-terminated input. A space immediately preceding a hard line ending or word joiner is not offered as a cut. The generator does not break inside arbitrary words or after zero-width joiners. NBSP is not a soft break.

`valid_source_breaks` checks strict ordering, bounds, required hard boundaries and a conservative subset of forbidden cuts (inside CRLF; immediately after a ZWJ/word joiner; before common combining marks). **This is not a conformance oracle for full Unicode text segmentation.** A caller supplying external breaks must independently qualify the Unicode/locale-specific provider, properties, mandatory and forbidden boundaries, source revision and coordinate conversion. Other combinations of marks, emoji and complex scripts are not fully validated here.

Official normative references: [Unicode 18.0.0 UAX #14 revision 57](https://www.unicode.org/reports/tr14/tr14-57.html) (line breaking) and [UAX #29 revision 49](https://www.unicode.org/reports/tr29/tr29-49.html) (grapheme boundaries). UAX #14 permits optional breaks at soft hyphens and notes that a chosen discretionary break can require language-dependent shaping/spelling changes. This pilot merely emits a visible ASCII hyphen as a documented and replaceable display policy.

## Reflow over source-bound breaks

`IB.Reflow.Source` exposes `reflow_source` (built-in restricted break generator) and `reflow_at_breaks` (provided breaks, checked before execution). Both return `SourceLine` spans. `source_for_line` recovers the exact original source slice from each span, even if display hides soft hyphens/zero-width marks/hard breaks or strips trailing display spaces. Concatenated source slices must exactly reconstruct the immutable source; the printed lines need not.

The selected algorithm is either greedy or a suffix-plan optimizer that scores squared/cubic/minimax whitespace, ignores the final line when requested, or minimizes line count before raggedness. Mandatory cuts cannot be crossed. A source run with no fitting optional cut remains overwide rather than being silently split inside a grapheme.

Supported on this **source-bound** input: `promptly`, `evenly`, `minimizing_raggedness`, `ignoring_final_line`, `minimizing_worst_gap`, `without_extra_lines`. The last is an exact minimum-line-count variant, unlike the earlier threshold-balance heuristic, and this distinction is observable.

Refused with an explicit error: `streamingly` (a stateful offset-preserving accumulator is needed) and `typographically` (the earlier Knuth–Plass *word-box* implementation requires glue/penalty data rather than silently interpreting raw source spaces as qualified glue). The original word-list implementations remain available for their own representation; a name match must not masquerade as the requested mechanism.

## Oracle cases and limits

The source-bound smoke tests include CRLF as one mandatory break, two adjacent hard breaks and an empty displayed line, source recovery across hidden controls, discretionary soft hyphens chosen or not chosen, zero-width space, CJK lines, NBSP nonbreaks, Hebrew text, combining-mark and emoji-ZWJ forbidden cuts, broken/missing/duplicate cuts, positive/zero width and explicit unavailable-mode refusal.

The source provider currently rescans `List Char` and builds/compares `Text` substrings during candidate search. **No amortized linearity, memory bound or fast ARM32 path is established.** The code is a semantic correctness and algorithm-choice trial, not a production native typography benchmark.

Remaining work: full versioned UAX #14/#29 provider, source-to-UTF-8-byte/UTF-16/glyph mappings, proper shaping and bidirectional painting, actual soft-hyphen/dictionary policy, narrow-to-wide-to-narrow selection anchor, native Android ARM32/ARM64 and Linux x86-64 execution, measured latency/allocations and independent wrong-output mutants.
