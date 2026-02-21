# ThreatWeave

yo. this is threatweave.

basically it's a super fast network intrusion detection system (nids) but written in ocaml 5 and c. it eats network packets really fast and looks for bad actors doing sketchy stuff on your network. built this to see how fast we can push packet correlation without the garbage collector ruining everything. 

### what it actually does

- **grabs packets**: uses a fake c ring-buffer (stubbed eBPF) because libpcap is too slow and annoying to set up for a weekend project.
- **ocaml brain**: reads from c via ctypes. we use jane street's `core` and `async` because standard library is pain. 
- **zero dispatch matching**: it categorizes threats in ocaml using pattern matching on steroids and `bin_prot` byte arrays. zero allocations. it just works.
- **state machine**: tracks the lifetime of a threat (like someone scanning ports, then downloading a payload, then phoning home) using generalized algebraic data types (gadts). the compiler literally won't let us write a bug where a state transitions wrong. 
- **clickhouse yeet**: dumps logs asynchronously to a clickhouse db for storage so we don't block the main pipe.

### use cases

when would you actually run this?
1. **catching zero days**: if a box gets popped and tries lateral movement, this catches the exact timeline of recon -> weaponization -> exfiltration.
2. **ddos/botnets**: tracks syn floods or weird dns beaconing across the network perimeter natively.
3. **hft-style analytics**: if your current firewall is bottlenecking at 100gbps and software routers are dying context switching, this approach keeps all the packet logic locked in userspace.

### how to run it

you need dune and ocaml 5.1+. just do:

```sh
dune build
dune exec threatweave
```

that's it. go crazy.
