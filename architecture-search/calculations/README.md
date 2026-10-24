# Calculations

Calculations derive comparable estimates before expensive measurement or search.

Useful calculations may cover operation counts, memory footprint, data movement, bandwidth, latency, code size, numerical error, and crossover points. They must state their assumptions and provenance. When an input is uncertain, preserve a range or interval instead of manufacturing a precise score.

Derived summaries should be reproducible from their inputs. A calculation can rule out an impossible candidate or identify what must be measured next; it should not disguise an unmeasured constant as fact.

## Worked estimates

- [Pauli and Wegert rotation](pauli-wegert-rotation-cost.md): source-derived operation counts, a 3.5× reduction in rotation-only arithmetic from ray-level reuse (not measured frame speed), and explicit unmeasured alternatives.
