(lang dune 3.10)
(name threatweave)
(generate_opam_files true)

(authors "ThreatWeave Team")
(maintainers "ThreatWeave Team")
(license "MIT")

(package
 (name threatweave)
 (synopsis "Real-Time Threat Correlation Engine")
 (description "Ultra-low latency NIDS driven by OCaml 5, Jane Street Core, and eBPF")
 (depends
  (ocaml (>= 5.1.0))
  (dune (>= 3.10))
  (core (>= v0.16.0))
  (async (>= v0.16.0))
  (ppx_jane (>= v0.16.0))
  (bin_prot (>= v0.16.0))
  (ctypes (>= 0.20.0))
 ))
