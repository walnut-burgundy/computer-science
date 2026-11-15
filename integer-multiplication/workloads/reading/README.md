# Sources for mathematical multiplication workloads

This is the MC-01 source audit. It reconciles the existing ComputerScience,
Fulton and Seifert shelves without copying books or claiming that cataloguing
created benchmark cases. The executable check validates the recorded identities,
relationships, finite-object arithmetic and refusal paths. Its PASS means the
audit is internally consistent; it does not mean MC-02–06 are implemented.

## What the audit inspected

[`bibliography.tsv`](bibliography.tsv) gives nine distinct source/edition
identities. [`observations.tsv`](observations.tsv) records exact primary or
pinned repository URLs, date, access/reading scope and inspected facts. Source
rights are deliberately link-only: online reading is not mirroring permission.
No full books, publisher pages or proprietary excerpts are copied here.

Silverman's author page identifies the original fourth edition as 2012. The
Pearson product page separately lists a Classic paperback 2017 update; its
heading also gives a 2014 publication / 2015 copyright. These are separate
records, not an inferred new edition. *Arithmetic Geometry* identifies Cornell
and Silverman as editors; its 2012 electronic publication does not replace the
1986 edition identity.

The source trail [`friendly-rsa-modulus`](source-map.tsv) comes from the actual
author-hosted web excerpt of Exercise 18.4(a). Its two integer factors and
displayed modulus are checked as an exact product. This is a source-to-finite-
object example, not a generator, timing sample, primality proof or measured
cryptographic workload. The typed observed triple is compared in full; incidental
digits in prose or ISBNs cannot supply substitute operands.

| Follow-on job | Source trail | Reading prerequisite |
|---|---|---|
| MC-02 | Author web excerpt Exercise 18.4(a) | Ready as a finite-object trail; choose and verify the requested general operand families separately |
| MC-03 | Silverman, *The Arithmetic of Elliptic Curves*, publisher TOC | Read an actual model/formula/example; retain field, coordinate and reduction boundaries |
| MC-04 | Fulton author edition and retained source record | Author PDF retrieval failed; inspect a named section/example before deriving coefficients or packing bounds |
| MC-05 | Morishita, *Alexander Modules and Iwasawa Modules*, publisher TOC; Seifert bridge | Read a concrete example and validate its matrix/polynomial; no coefficients have been extracted |
| MC-06 | Hindry–Silverman *Height Functions*; Cornell–Silverman height chapters, publisher TOCs | Read a specific definition/example before deriving integer numerator/denominator growth |

Publisher TOCs are navigation evidence. Their chapter titles are not claims that
the chapters were read. The current Fulton URL returned a retrieval failure
(502); the alternate `dept.math` host returned 404. Access availability is a
dated observation, not a permanent claim about the book.

## The unidentified title

*Plane Algebraic Curves* remains `plane-curves-unresolved`. A full default-branch
history search of `books` and `integer-multiplication` for that exact title
returned no match at the audited ComputerScience base. Authoritative records
show at least two distinct same-titled works: [Gerd Fischer, AMS Student
Mathematical Library 15](https://doi.org/10.1090/stml/015), and
[Egbert Brieskorn and Horst Knörrer, Birkhäuser](https://doi.org/10.1007/978-3-0348-0493-6).
Those records establish ambiguity; they do not identify the user's intended
book. Fulton's *Algebraic Curves* is not silently substituted.

## Repository ownership and reciprocal links

[`repository-links.tsv`](repository-links.tsv) pins the audited shelves and
named frontend/specification. These are references inspected during this audit,
not runtime network checks. The existing [Fulton source record](https://github.com/walnut-burgundy/fulton/blob/5ae8ae3a5ca7e827c8208daa42839ae4e8233e65/sources/fulton-algebraic-curves/README.md)
links back to ComputerScience and Seifert. The existing [Seifert arithmetic
bridge](https://github.com/isomorphismes/seifert/blob/dfbffe3670c2ca2e9e067d23893fc4a7b78ad6ce/books/arithmetic-examples-for-multiplication.md)
links back to ComputerScience and Fulton. Their canonical source ownership is
preserved; this branch only changes ComputerScience. The historical
`dilapidated-shed/ick` repository has transferred to
[`isomorphisms/ick`](https://github.com/isomorphisms/ick).

## Run the check

Use `isomorphisms/ithon` pinned at
`74ab6d6044b07b76a910978437a34a6b5ac6acda`, entrypoint `ithon` at its repository
root. Pass the absolute path of `check_mc01.pi`. With no arguments it validates
the sibling tables from any launch directory. Add `--self-test` followed by the
absolute Ithon entrypoint to execute a positive child and fifteen corrupted
tables through the same checked frontend. Every refusal must have a nonzero
outer status and its expected diagnostic. Missing tables, invalid UTF-8,
duplicate identities, fabricated operands, falsely claimed reading, unresolved
author selection, edition conflation, editor misattribution, omitted consumers,
unauthorized mirroring and floating dependencies are exercised.

The check emits SHA-256 identities for its exact source and input tables. Set
Ithon's `ITHON_CHECK_RECEIPT` to an absolute receipt path when a machine-readable
frontend-check record is also needed. [`validation.tsv`](validation.tsv) records
the performed local command, host and results. The original assignment's
`python3 .../check_mc01.py` interface is superseded by current checked-Ithon
policy; no new maintained Python wrapper was introduced.

The [Idriç attempt record](../../../examples/autogenerated/reading-provenance/attempt.md)
distinguishes the unexecuted domain sketch from this executed Ithon verifier.
Neither qualifies a multiplier, reads whole books, implements MC-02–06, or
supplies physical-device evidence.
