open Core
open Async
open Types

(* dumping data into the void *)
let push_to_ch batch =
  printf "yeeting %d rows to ch...\n" (List.length batch);
  let%bind () = Clock.after (Time_float.Span.of_ms 5.) in
  return ()

let yeet_loop pipe =
  let rec loop () =
    match%bind Pipe.read pipe with
    | `Eof -> return ()
    | `Ok stuff -> 
        let%bind () = push_to_ch [stuff] in
        loop ()
  in loop ()
