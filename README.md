# ThreatWeave

**ThreatWeave** is a Real-Time Threat Correlation Engine designed for ultra-low latency Network Intrusion Detection. Building upon the principles of High-Frequency Trading (HFT) infrastructure, it correlates 200K+ concurrent security events across distributed sensors. 

## Technical Architecture

ThreatWeave fuses the raw speed of C (eBPF / AF_XDP for packet capture) with the high-level concurrency and safety of OCaml 5.x. We leverage Jane Street's world-class ecosystem (`Core`, `Async`, and `bin_prot`) to ensure zero-allocation message passing between the kernel space and our correlative state machine.

### Key Features
- **OCaml 5 Multicore + Async**: Utilizes effects-based concurrency to parallelize network flow aggregations.
- **`bin_prot` Zero-copy Ingestion**: Network frames from C directly map to OCaml records without garbage collection spikes.
- **GADT-Powered State Validation**: The threat correlation engine ensures kill-chain anomalies strictly follow logical escalation paths at compile time.
- **Fast Pattern Matching**: Zero-day threat heuristics are dispatched in `O(1)` routing jumps via OCaml's deep pattern matching structures.

## Roadmap & HFT Principles Applied
ThreatWeave employs several tricks used in high-frequency computational finance:
1. **Minimizing GC Pauses**: Pre-allocated structures and flat arrays (`Bigstring`) when ingesting wire data. `bin_prot` decodes byte sequences directly into OCaml primitives safely.
2. **Actor-Based Pipes**: Pipelined data flow using `Async.Pipe` providing natural backpressure and lock-free concurrency.
3. **Branch Elimination**: Efficient data type modeling (`int32` for IPs instead of mutable strings or arrays) ensures we remain strictly inside the CPU cache lines.

## How to Build

*Requires dune, opam, and an OCaml 5.1+ toolchain.*

```bash
dune build
dune exec threatweave
```
