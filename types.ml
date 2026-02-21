open Core

(* 
   HFT-grade Threat Event definitions using bin_prot for zero-allocation
   binary serialization directly from the C network loop.
*)

module Protocol = struct
  type t =
    | TCP
    | UDP
    | ICMP
    | HTTP
    | DNS
  [@@deriving sexp, bin_io, compare, hash]
end

(* Optimized IPv4 representation (avoiding string allocations) *)
module Ipv4 = struct
  type t = int32 [@@deriving sexp, bin_io, compare, hash]
  
  let to_string ip = 
    let b1 = Int32.bit_and (Int32.shift_right_logical ip 24) 255l |> Int32.to_int_exn in
    let b2 = Int32.bit_and (Int32.shift_right_logical ip 16) 255l |> Int32.to_int_exn in
    let b3 = Int32.bit_and (Int32.shift_right_logical ip 8) 255l |> Int32.to_int_exn in
    let b4 = Int32.bit_and ip 255l |> Int32.to_int_exn in
    sprintf "%d.%d.%d.%d" b1 b2 b3 b4
end

(* Fundamental network event layout ingested from C ring buffer *)
type raw_event = {
  timestamp_ns: int64;
  src_ip: Ipv4.t;
  dst_ip: Ipv4.t;
  src_port: int;
  dst_port: int;
  protocol: Protocol.t;
  payload_len: int;
} [@@deriving sexp, bin_io, compare]

(* Advanced ADTs mapping raw packets to security semantics *)
type threat_signature =
  | Port_Scan_Attempt of { target_port: int; consecutive_failures: int }
  | Syn_Flood
  | Data_Exfiltration_Anomaly of { bytes_out: int; entropy_score: float }
  | Dga_Beacon of { domain_hash: int64 }
  | Malformed_Protocol
  [@@deriving sexp, bin_io, compare]

type parsed_event = {
  raw: raw_event;
  sig_match: threat_signature option;
} [@@deriving sexp, bin_io]

(* 
   GADTs for State-Machine validation at compile time.
   Provides absolute guarantees that threats move logically through a kill-chain.
*)
type recon_state
type weaponized_state
type exfiltrating_state

type _ kill_chain_state =
  | Recon : raw_event list -> recon_state kill_chain_state
  | Weaponization : recon_state kill_chain_state * event_sequence -> weaponized_state kill_chain_state
  | Exfiltration : weaponized_state kill_chain_state * int -> exfiltrating_state kill_chain_state
and event_sequence = parsed_event list

type active_threat =
  | Threat : 'state kill_chain_state -> active_threat
