# Paper-model record — analysis, not execution

Anchor: openai/math adc7f1241b42e322a6451854ab7e4b4c146bf78a.
Fixed finite alphabet, fixed number of one-dimensional tapes; moving a head by one
cell costs one step. Logical bit volume excludes duplicate work streams but their
copying, scanning, rewinding and clearing are charged. Descriptor preparation, finite
network generation, prime search, precision growth and recursive calls must be charged.

Source analysis gives Wb=177176569091445000000, Wc=1873807244643542670000,
m=1000000 and corrected summed ranks sb=177176569088785861287000000,
sc=1873807244636671267308000000, each <Wm. The normalized recurrence coefficient
is s/W. These constants and the published inequalities are extracted source claims,
not independently proved by the bounded host experiments.

The implementation plan records exactness and preparation obligations per node.
No full fixed-tape interpreter, head-movement trace, or independent recurrence proof
was implemented in STAR MUL-0. The native array host model cannot supply that evidence.
