open Core
open Async
open Types

(* the udp bouncer. lets external apps (python, go) yeet packets at us *)

let serve_wrapper pipe_writer port =
  printf "starting udp bouncer on port %d for our 3rd party friends...\n" port;
  
  let handle_datagram _sock ~source_addr:_ msgbuf =
    (* in a real pro system, we'd use bin_prot to deserialize bytes.
       for now, we just pretend we deserialized cool stuff and pump fake garbage 
       to test the pipe throughput. *)
    let len = Iobuf.length msgbuf in
    if len > 0 then (
      let fake_pkt = {
        ts = Time_ns.(now () |> to_int63_ns_since_epoch |> Int63.to_int64);
        src = Random.int32 Int32.max_value;
        dst = Random.int32 Int32.max_value;
        sport = Random.int 65535;
        dport = 80;
        proto = Proto.Tcp;
        len = len;
      } in
      Pipe.write_without_pushback_if_open pipe_writer fake_pkt
    )
  in

  let addr = Socket.Address.Inet.create (Unix.Inet_addr.of_string "127.0.0.1") ~port in
  let%bind _sock = 
    Udp.bind addr 
    >>= fun sock -> Udp.recvfrom_loop sock handle_datagram 
  in
  return ()
