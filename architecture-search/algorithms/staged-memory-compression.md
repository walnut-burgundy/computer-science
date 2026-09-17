# Staged memory compression

Status: architecture-search input, not an implemented planner rule.

The semantic problem is broader than choosing one compression library. On a low-RAM system, data can move through several representations over time:

```text
hot data
  -> ordinary RAM

recently cold data
  -> nearly free, fast compression

older cold data while compute is idle
  -> opportunistic denser recompression

still cold under memory pressure
  -> bounded backing storage where the platform permits it

likely to be used again
  -> prefetch / cheap decompression toward the active working set
```

The planner should choose the representation and execution path from target facts and measurements rather than hard-code one codec or processor.

## Primary decision principle

Optimize the user-visible retrieval path, not compression ratio alone.

A candidate's cost includes:

```text
restore cost
  = storage read, if any
  + decompression
  + fault / runtime bookkeeping
  + scheduler delay
  + time until the useful working set is available
```

Track tail latency as well as average throughput. A denser codec is not an improvement if it creates a noticeable application-return pause.

## Staged work

The first pass should be cheap enough to run directly on the reclaim path. LZ4-like algorithms are natural candidates because the main objective is to recover RAM without spending much CPU time.

A later pass may spend more work on pages or objects that have demonstrated that they are cold. zstd-like algorithms are natural candidates for this secondary role. Compression level remains a decision variable, not a constant.

Archive-oriented codecs remain available to the broader planner, but should not enter an interactive memory tier merely because their compression ratio is high.

## Opportunistic scheduling

Deeper recompression should behave as polite background work:

- low scheduler priority;
- immediate yielding to interactive work;
- idle-time preference;
- battery and thermal constraints;
- explicit CPU/energy budget;
- minimum expected memory saving before doing work.

The planner may consider an idle GPU as another compute resource, but GPU recompression is an experiment rather than a default. For small pages, dispatch, synchronization, driver wake-up, and data movement can dominate. Batch size therefore belongs in the decision record.

## Required measurements

For each target and workload preserve:

- codec and level;
- CPU/GPU/backend path;
- input size and content class;
- compressed size;
- compression time;
- decompression median/p95/p99;
- energy/thermal state where measurable;
- batch size;
- complete application restore latency where relevant.

Performance claims must remain target-specific.

## Android reference implementation

`isomorphisms/zram` is the concrete Android/low-RAM experiment. It records Linux zram, Android `lmkd`, Android 17 `mmd`, internal-storage writeback, the MIRO A1 target dossier, and physical-device measurements.

Android 17 `mmd` is useful precedent for the staged model: fast initial zram compression, later denser recompression, optional bounded writeback, and per-process prefetch/writeback. That upstream design is reference evidence, not proof that an older Android Go target implements it.

## Language/compiler boundary

Idriç/Edriç should preserve the high-level policy and constraints. ComputerScience should choose an implementation from target evidence. The selected lowering does not have to pass through C: a framework-side action may lower to DEX, a kernel/native action to machine code, and a GPU experiment to a compute/shader target.

The planner should therefore record both the selected path and rejected alternatives rather than treating one implementation language as part of the semantic operation.
