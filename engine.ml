open Core
open Types

(* 
   High-performance correlation heuristics.
   Uses OCaml's extremely fast pattern matching to branch logic with zero dispatch overhead. 
*)

let rate_limit_table = Hashtbl.create (module Ipv4)

let analyze_packet (event : raw_event) : parsed_event =
  (* Fast path O(1) pattern matching based on standard protocols *)
  let sig_match = 
    match event.protocol, event.dst_port, event.payload_len with
    | Protocol.TCP, dst, 0 when dst > 1024 -> 
       Some (Port_Scan_Attempt { target_port = dst; consecutive_failures = 1 })
    | Protocol.DNS, 53, len when len > 512 ->
       Some (Dga_Beacon { domain_hash = 0L }) (* Stubbed hash *)
    | Protocol.TCP, _, len when len > 100_000 ->
       Some (Data_Exfiltration_Anomaly { bytes_out = len; entropy_score = 0.9 })
    | _ -> None
  in
  { raw = event; sig_match }

let correlate_threats (parsed : parsed_event) (current_state : active_threat option) : active_threat option =
  match current_state, parsed.sig_match with
  | None, Some (Port_Scan_Attempt _) ->
      (* Transition from Nothing -> Reconnaissance *)
      Some (Threat (Recon [parsed.raw]))
      
  | Some (Threat (Recon recon_events)), Some (Data_Exfiltration_Anomaly { bytes_out; _ }) ->
      (* Escalation from Reconnaissance -> Weaponization *)
      let weaponized = Weaponization (Recon recon_events, [parsed]) in
      Some (Threat weaponized)
      
  | Some (Threat (Weaponization (r, es))), Some (Dga_Beacon _) ->
      (* Final Escalation -> Exfiltration Command & Control Drop *)
      let exfil = Exfiltration (Weaponization (r, es), 1) in
      Some (Threat exfil)

  | state, _ -> state (* No state change *)
