# Checked hostile-ingestion capability boundary

This directory pins the executable vocabulary from
`isomorphisms/ai-ci/ingestion` by full commit SHA. The canonical corpus lives in
`ai-ci`; it is not copied here.

The capability receipt is intentionally all `SKIP`. This repository defines and
reviews the language boundary, but it does not contain the ingestion executable.
CI verifies that `SKIP` is recorded as the first incomplete boundary rather than
turning “not run” into success.

The first implementation-under-test receipt is produced in ICU. It identifies
the current Idriç plus native-C ownership split, compares against separate
curl/libxml2 oracle receipts, and prevents the candidate from invoking that
oracle. Passing ICU fixtures do not establish the rest of the capability matrix:
timeouts, cancellation, streaming/chunk boundaries, bounded resource failures,
WARC, full HTML recovery, and a browser DOM remain separate work.

The shared order is:

`input acquisition → network → decompression → decoding → HTML recovery → document construction → downstream extraction`

The internal document name is `document_log_subset_v0` until executable evidence
supports a stronger claim.
