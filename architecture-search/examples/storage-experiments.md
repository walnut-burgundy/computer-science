# Storage and memory experiment repositories

These repositories are concrete experiments that ComputerScience may later use as evidence when choosing storage and memory architecture. Their existence does not make their designs universal planner rules.

## `isomorphisms/zram`

Repository: https://github.com/isomorphisms/zram

Question: how should a low-RAM Android system preserve useful background process state before resorting to process death?

Current design space:

```text
RAM
  -> fast zram compression
  -> opportunistic denser recompression
  -> bounded writeback to internal /data storage
  -> process kill as a later resort
```

The experiment also distinguishes Android task/Activity reconstruction from actual process survival, and records the MIRO A1 target down to physical-device receipts where available.

ComputerScience should eventually consume measurements from this repository when choosing codec, compression level, CPU/GPU execution path, writeback policy, prefetch policy, and the point at which keeping a process alive is more expensive than recreating it.

## `isomorphisms/sd-card-append-fat`

Repository: https://github.com/isomorphisms/sd-card-append-fat

Question: how far can a deliberately append-oriented filesystem/storage design simplify write behavior and make sequential storage explicit on removable media?

This is a separate storage experiment from zram. Do not treat removable SD storage as the backing tier for the zram experiment merely because both investigate flash-backed storage.

The useful ComputerScience relationship is that both expose a choice usually hidden behind a conventional operating-system interface:

- zram asks when data should change representation or move between memory tiers;
- append-fat asks what storage representation and update discipline should be used for append-oriented durable data.

They should remain distinct semantic choices. A planner may eventually compose them only when the target, workload, durability requirements, and measurements justify doing so.

## Evidence rule

For both repositories, preserve:

- exact target/device/filesystem facts;
- source and specification provenance;
- measurements rather than generic performance folklore;
- selected and rejected alternatives;
- the difference between a design proposal, host/emulator result, and physical-device acceptance.
