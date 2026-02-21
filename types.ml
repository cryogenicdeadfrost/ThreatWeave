open Core

module Proto = struct
  type t = Tcp | Udp | Icmp | Http | Dns
  [@@deriving sexp, bin_io, compare, hash]
end

(* ints are cheaper than strings lol *)
module Ipv4 = struct
  type t = int32 [@@deriving sexp, bin_io, compare, hash]
  let to_str ip = 
    let f n = Int32.bit_and (Int32.shift_right_logical ip n) 255l |> Int32.to_int_exn in
    sprintf "%d.%d.%d.%d" (f 24) (f 16) (f 8) (f 0)
end

type packet_boi = {
  ts: int64;
  src: Ipv4.t;
  dst: Ipv4.t;
  sport: int;
  dport: int;
  proto: Proto.t;
  len: int;
} [@@deriving sexp, bin_io, compare]

type bad_vibes =
  | Knock_Knock of { port: int; fails: int }
  | Syn_Spam
  | Mega_Yeet of { bytes: int; entropy: float }
  | Dga_Sus of { hash: int64 }
  | Wtf_Proto
  [@@deriving sexp, bin_io, compare]

type sus_packet = {
  raw: packet_boi;
  vibe_check: bad_vibes option;
} [@@deriving sexp, bin_io]

(* compiler magic to prevent stupid state bugs *)
type snooping
type pewpew
type yoinking

type _ kill_chain =
  | Snooping : packet_boi list -> snooping kill_chain
  | PewPew : snooping kill_chain * sus_packet list -> pewpew kill_chain
  | Yoinking : pewpew kill_chain * int -> yoinking kill_chain

type active_baddie =
  | Baddie : 'state kill_chain -> active_baddie
