# MC-01 reading provenance

## Types and intended actions

The values are bibliography identities, edition identities, legal access URLs,
observations, source passages and finite mathematical objects. Bibliography
identity is not title equality: the original fourth edition and its Classic
reprint have separate identities. An unidentified title is an unresolved object,
not permission to choose an author.

The intended operations are `audit reading_sources → Audit` and
`connect source_passage to finite_object → SourceTrail`. Audit errors include
duplicate identities, missing observations, falsely claimed reading, invented
passages, unauthorized mirroring and omitted consumer obligations. Reading a
TSV file is an effect; checking its internal relationships is a pure operation.
No network access or benchmark generation happens during validation.

The small Idriç domain attempt is `ReadingState.idric`. It separates catalogue
access from a read passage and permits a source-to-object trail only for a read
passage. The full desired implementation also needs checked UTF-8 file input,
TSV decoding, maps, process exit statuses and receipts. These are not claimed
implemented by the attempt.

## Execution choice and evidence

`command -v idric` returned exit 1 on the Linux x86_64 build host on 2026-11-15.
The Idriç attempt is therefore NOT_RUN, not a compiler rejection or an accepted
Idriç program. No RefC or generated-C path was tried. A current usable Idriç
compiler/runtime was not established for this consumer.

The repository's shared ai-ci instructions require new Python-family programs
to use checked Ithon `.pi`. The implementation is `check_mc01.pi`, run through
the actual `isomorphisms/ithon` entrypoint at
`74ab6d6044b07b76a910978437a34a6b5ac6acda`. Its checked host frontend qualification
passed all 46 tests before this verifier was attempted. That host frontend has
an inherited Python implementation substrate; it is not direct native Idriç.

The first Ithon attempts were refused by the actual frontend for set literals,
generator expressions, negative membership and string iteration, and for foreign
method results used before a typed extraction. The implementation now uses
typed lists, explicit loops and narrow typed extraction points. These were real
frontend failures, not passing source checks; no plain-Python execution bypass
was introduced. Checked final execution and all fifteen refusal subprocesses
pass. The typed observation triple prevents incidental digits in source prose
from falsely admitting a fabricated operand pair.

The old assignment named `python3 .../check_mc01.py`. Current language policy
supersedes that spelling; no new first-party `.py` wrapper is added. Invoke
the pinned Ithon frontend with the absolute path of `check_mc01.pi`.

## Acceptance boundary

The verifier checks recorded relationships and negative controls. It cannot
prove an editor actually read a book or that a publisher grants redistribution.
The human/source audit records those observations, and failures remain explicit.
One inspected author-hosted numerical exercise supplies a concrete finite-object
trail. Other follow-on jobs retain precise reading/access blockers. No MC-02–06
generator, multiplier benchmark or full-book reading is claimed.

## Next Idriç language work

First establish a maintained compiler entrypoint for this consumer, check and
execute `ReadingState.idric`, then port the same UTF-8/table/refusal tests. The
replacement acceptance must preserve duplicate-ID, invented-passage,
unauthorized-mirror and dropped-consumer refusals before Ithon is removed.
