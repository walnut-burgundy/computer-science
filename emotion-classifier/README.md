# Emotion classifier as a filesystem relation

Canonical labeled corpus: `bl4ckb4ll/syllabus/poetry/emotions/`.

Syllabus keeps each work once and represents emotion membership with symbolic links from emotion directories to the canonical item. This is a concrete many-to-many classification structure rather than a duplicated directory tree.

Initial labels: Anger; Anxiety & Insecurity; Blame & Guilt; Boredom; Disappointment; Gratitude; Grief; Humor; Joy & Contentment; Melancholy & Despair; Optimism; Passion.

## Reuse

This structure is intended to be reused as training/evaluation data for a learned multi-label classifier. The important design properties are:

- one canonical object, many label edges;
- label membership encoded separately from object storage;
- human-editable reference labels;
- model output can be materialized as proposed symlink edges without rewriting the source object;
- train/test splitting operates on canonical objects, not symlinks, to avoid leakage;
- the same relation can later classify material other than poems.

`isomorphisms/ai-ci` is expected to host evaluation/acceptance work; `isomorphisms/rhs` can use the reference label set as an oracle for generated classifier output; `isomorphisms/Idric` may later consume or produce the classifier representation.

This is a design note only, not a claim that a trained classifier exists yet.
