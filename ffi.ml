open Ctypes
open Foreign

type c_pkt
let c_pkt : c_pkt structure typ = structure "fake_packet_t"
let f_ts = field c_pkt "ts" int64_t
let f_src = field c_pkt "src" uint32_t
let f_dst = field c_pkt "dst" uint32_t
let f_sport = field c_pkt "sport" int
let f_dport = field c_pkt "dport" int
let f_proto = field c_pkt "proto" int
let f_len = field c_pkt "len" int
let () = seal c_pkt

let grab_packet = foreign "grab_packet" (ptr c_pkt @-> returning int)
let init_bpf = foreign "init_bpf" (void @-> returning int)
