open Core
open Async

module T = Types
module E = Engine

(*
   HFT-Style Async Pipeline.
   In a production environment, reading from the C-Ring buffer occurs here via Ctypes.
   For this scaffolding, we simulate a massive influx of dummy events to validate pipeline speed.
*)

let generate_mock_event () =
  {
    T.timestamp_ns = Time_ns.(now () |> to_int63_ns_since_epoch |> Int63.to_int64);
    src_ip = Random.int32 Int32.max_value;
    dst_ip = Random.int32 Int32.max_value;
    src_port = Random.int 65535;
    dst_port = Random.int 65535;
    protocol = T.Protocol.TCP;
    payload_len = Random.int 1500;
  }

let simulate_ingestion (writer : T.raw_event Pipe.Writer.t) =
  let rec loop count =
    if count = 0 then (
      Pipe.close writer;
      return ()
    ) else (
      (* Pumping 200k events *)
      Pipe.write_without_pushback_if_open writer (generate_mock_event ());
      if count % 1000 = 0 then
        let%bind () = Scheduler.yield () in
        loop (count - 1)
      else
        loop (count - 1)
    )
  in
  loop 200_000

let process_pipeline (reader : T.raw_event Pipe.Reader.t) =
  let threat_states = Hashtbl.create (module T.Ipv4) in
  
  let processor_loop () =
    Pipe.iter reader ~f:(fun raw_event ->
      let parsed = E.analyze_packet raw_event in
      
      let current_state = Hashtbl.find threat_states raw_event.src_ip in
      let next_state = E.correlate_threats parsed current_state in
      
      (match next_state with
       | Some state -> Hashtbl.set threat_states ~key:raw_event.src_ip ~data:state
       | None -> ());
       
      return ()
    )
  in
  
  let start_time = Time_now.nanoseconds_since_start_of_day () in
  let%bind () = processor_loop () in
  let end_time = Time_now.nanoseconds_since_start_of_day () in
  let diff_ms = Int63.((end_time - start_time) / of_int 1_000_000) |> Int63.to_int_exn in
  
  printf "[ThreatWeave] Processed 200,000 events in %d ms.\n" diff_ms;
  printf "[ThreatWeave] Active tracked threats: %d\n" (Hashtbl.length threat_states);
  return ()

let main () =
  let (reader, writer) = Pipe.create () in
  
  printf "[ThreatWeave] Booting Real-Time Correlation Engine...\n";
  
  (* Launch ingestion and processing in parallel *)
  don't_wait_for (simulate_ingestion writer);
  
  let%bind () = process_pipeline reader in
  
  printf "[ThreatWeave] Graceful shutdown.\n";
  Shutdown.exit 0

let () =
  Command.async
    ~summary:"Start the ThreatWeave correlation engine"
    (Command.Param.return main)
  |> Command_unix.run
