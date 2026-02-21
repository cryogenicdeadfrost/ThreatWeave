open Core
open Async
module T = Types
module E = Engine

(* the big brain logic. does all the heavy lifting *)
let brain reader ch_writer =
  let baddies = Hashtbl.create (module T.Ipv4) in
  let work () =
    Pipe.iter reader ~f:(fun pkt ->
      let vibes = E.vibe_check pkt in
      let curr = Hashtbl.find baddies pkt.src in
      let next = E.do_math vibes curr in
      (match next with
       | Some b -> 
           Hashtbl.set baddies ~key:pkt.src ~data:b;
           Pipe.write_without_pushback_if_open ch_writer vibes
       | None -> ());
      return ()
    )
  in
  let t0 = Time_now.nanoseconds_since_start_of_day () in
  let%bind () = work () in
  let t1 = Time_now.nanoseconds_since_start_of_day () in
  let ms = Int63.((t1 - t0) / of_int 1_000_000) |> Int63.to_int_exn in
  printf "brain stopped. ate everything in %d ms.\n" ms;
  printf "found %d baddies sitting in the hash map.\n" (Hashtbl.length baddies);
  return ()

let run_simulation () =
  let (r, w) = Pipe.create () in
  let (ch_r, ch_w) = Pipe.create () in
  
  printf "firing up local simulation loop (benchmarking)...\n";
  let _ = Ffi.init_bpf () in
  
  (* local firehose just for testing benchmarks *)
  let firehose () =
    let rec loop n =
      if n = 0 then (Pipe.close w; return ())
      else (
        let pkt = {
          T.ts = Time_ns.(now () |> to_int63_ns_since_epoch |> Int63.to_int64);
          src = Random.int32 Int32.max_value; dst = Random.int32 Int32.max_value;
          sport = Random.int 65535; dport = Random.int 65535;
          proto = T.Proto.Tcp; len = Random.int 1500;
        } in
        Pipe.write_without_pushback_if_open w pkt;
        if n % 1000 = 0 then let%bind () = Scheduler.yield () in loop (n - 1) else loop (n - 1)
      )
    in loop 200_000
  in

  don't_wait_for (firehose ());
  don't_wait_for (Clickhouse.yeet_loop ch_r);
  
  let%bind () = brain r ch_w in
  Shutdown.exit 0

let run_daemon port =
  let (r, w) = Pipe.create () in
  let (ch_r, ch_w) = Pipe.create () in
  
  printf "ready to receive packets on port %d... (press ctrl-c to stop)\n" port;
  don't_wait_for (Daemon.serve_wrapper w port);
  don't_wait_for (Clickhouse.yeet_loop ch_r);
  
  let%bind () = brain r ch_w in
  Shutdown.exit 0

let main () =
  Command.group ~summary:"ThreatWeave NIDS - Super chill threat correlation"
    [ 
      "sim", Command.async ~summary:"Run a local 200k packet benchmark" 
             (Command.Param.return run_simulation);
             
      "daemon", Command.async ~summary:"Listen on UDP for 3rd party wrappers"
             (let%map_open.Command port = anon ("port" %: int) in
              fun () -> run_daemon port)
    ]
  |> Command_unix.run
