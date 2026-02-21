open Core
open Types

let blacklist = Hashtbl.create (module Ipv4)

let vibe_check (pkt : packet_boi) : sus_packet =
  let vibe = 
    match pkt.proto, pkt.dport, pkt.len with
    | Proto.Tcp, p, 0 when p > 1024 -> Some (Knock_Knock { port = p; fails = 1 })
    | Proto.Dns, 53, l when l > 512 -> Some (Dga_Sus { hash = 0L }) 
    | Proto.Tcp, _, l when l > 100_000 -> Some (Mega_Yeet { bytes = l; entropy = 0.9 })
    | _ -> None
  in
  { raw = pkt; vibe_check = vibe }

let do_math (parsed : sus_packet) (state : active_baddie option) =
  match state, parsed.vibe_check with
  | None, Some (Knock_Knock _) -> Some (Baddie (Snooping [parsed.raw]))
  | Some (Baddie (Snooping sn)), Some (Mega_Yeet _) -> Some (Baddie (PewPew (sn, [parsed])))
  | Some (Baddie (PewPew (sn, pew))), Some (Dga_Sus _) -> Some (Baddie (Yoinking (PewPew (sn, pew), 1)))
  | curr, _ -> curr
