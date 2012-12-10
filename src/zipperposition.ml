(*
Zipperposition: a functional superposition prover for prototyping
Copyright (C) 2012 Simon Cruanes

This is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
02110-1301 USA.
*)

(** Main file for the prover *)

open Types
open Params

module T = Terms
module O = Orderings
module C = Clauses
module I = Index
module PS = ProofState
module CQ = ClauseQueue
module S = FoSubst
module Utils = FoUtils
module Unif = FoUnif
module Sup = Superposition
module Sat = Saturate
module Sel = Selection
module Delayed = Delayed
  
(* random generator initialization *)
let seed = ref 1928575

let version = "0.2"

(** parse_args returns parameters *)
let parse_args () =
  let help_select = Utils.sprintf "selection function (@[<h>%a@])"
    (Utils.pp_list ~sep:"," Format.pp_print_string)
    (Sel.available_selections ())
  and help_index = Utils.sprintf "indexing structure (@[<h>%a@])"
    (Utils.pp_list ~sep:"," Format.pp_print_string)
    (PS.names_index ()) in
  let unamed_skolem () = Calculus.skolem := Calculus.unamed_skolem in
  (* parameters *)
  let ord = ref "rpo6"
  and steps = ref 0
  and version = ref false
  and timeout = ref 0.
  and proof = ref true
  and output = ref "debug"
  and index = ref "fp"
  and theories = ref true
  and calculus = ref "superposition"
  and presimplify = ref false
  and heuristic_precedence = ref true
  and dot_file = ref None
  and select = ref "SelectComplex"  (* TODO choose clause queues? *)
  and progress = ref false
  and print_sort = ref false
  and print_all = ref false
  and file = ref "stdin" in
  (* options list *) 
  let options =
    [ ("-ord", Arg.Set_string ord, "choose ordering (rpo,kbo)");
      ("-debug", Arg.Int Utils.set_debug, "debug level");
      ("-version", Arg.Set version, "print version");
      ("-steps", Arg.Set_int steps, "verbose mode");
      ("-unamed-skolem", Arg.Unit unamed_skolem, "unamed skolem symbols");
      ("-profile", Arg.Set HExtlib.profiling_enabled, "enable profile");
      ("-calculus", Arg.Set_string calculus, "set calculus ('superposition' or 'delayed')");
      ("-timeout", Arg.Set_float timeout, "verbose mode");
      ("-select", Arg.Set_string select, help_select);
      ("-progress", Arg.Set progress, "print progress");
      ("-no-theories", Arg.Clear theories, "do not detect theories in input");
      ("-no-heuristic-precedence", Arg.Clear heuristic_precedence, "do not use heuristic to choose precedence");
      ("-noproof", Arg.Clear proof, "disable proof printing");
      ("-presimplify", Arg.Set presimplify, "pre-simplify the initial clause set");
      ("-dot", Arg.String (fun s -> dot_file := Some s) , "print final state to file in DOT");
      ("-output", Arg.Set_string output, "output syntax ('debug', 'tstp')");
      ("-index", Arg.Set_string index, help_index);
      ("-print-sort", Arg.Set print_sort, "print sorts of terms");
      ("-print-all", Arg.Set print_all, "print desugarized terms (lambdas, De Bruijn terms)");
      ("-print-ord", Arg.Unit (fun () -> C.pp_literal_debug#ord true), "print order of sides of literals");
    ]
  in
  Arg.parse options (fun f -> file := f) "solve problem in first file";
  (* return parameter structure *)
  { param_ord = !ord; param_steps = !steps; param_version= !version; param_calculus = !calculus;
    param_timeout = !timeout; param_files = [!file]; param_select = !select; param_theories= !theories;
    param_progress = !progress; param_proof = !proof; param_presimplify = !presimplify;
    param_output_syntax = !output; param_index= !index; param_dot_file = !dot_file;
    param_print_sort = !print_sort; param_print_all = !print_all; param_precedence= !heuristic_precedence;}

(** find the given file from given directory *)
let find_file name dir =
  (* check if the file exists *)
  let rec file_exists name =
    try ignore (Unix.stat name); true
    with Unix.Unix_error (e, _, _) when e = Unix.ENOENT -> false
  (* search recursively from dir *)
  and search path cur_name =
    Utils.debug 3 (lazy (Utils.sprintf "%% search %s as %s@." name cur_name));
    match path with
    | _ when file_exists cur_name -> cur_name (* found *)
    | [] -> failwith ("unable to find file " ^ name)
    | _::path' ->
      let new_dir = List.fold_left Filename.concat "" (List.rev path') in
      let new_name = Filename.concat new_dir name in
      search path' new_name
  in
  if Filename.is_relative name
    then
      let r = Str.regexp Filename.dir_sep in
      let path = List.rev (Str.split r dir) in
      search path (Filename.concat dir name)
    else if file_exists name then name else failwith ("unable to find file " ^ name)

(** parse given tptp file *)
let parse_file ~recursive f =
  let dir = Filename.dirname f in
  (* [aux files clauses] parses all files in files and add
     the resulting clauses to clauses *)
  let rec aux files clauses = match files with
  | [] -> clauses
  | f::tail ->
    let new_clauses, new_includes = parse_this f in
    if recursive
      then aux (List.rev_append new_includes tail) (List.rev_append new_clauses clauses)
      else (List.rev_append new_clauses clauses)
  (* parse the given file, raise exception in case of error *)
  and parse_this f =
    let input = match f with
    | "stdin" -> stdin
    | _ -> open_in (find_file f dir) in
    try
      let buf = Lexing.from_channel input in
      Const.cur_filename := f;
      Parser_tptp.parse_file Lexer_tptp.token buf
    with _ as e -> close_in input; raise e
  in aux [Filename.basename f] []

(** setup index *)
let setup_index name =
  PS.cur_index := I.mk_clause_index (PS.choose_index name);
  Format.printf "%% use indexing structure %s@." name

(** print stats *)
let print_stats state =
  let print_hashcons_stats what (sz, num, sum_length, small, median, big) =
    Printf.printf "%% hashcons stats for %s: size %d, num %d, sum length %d, buckets: small %d, median %d, big %d\n"
      what sz num sum_length small median big
  and print_state_stats (num_active, num_passive) =
    Printf.printf "%% proof state stats:\n";
    Printf.printf "%%   active clauses   %d\n" num_active;
    Printf.printf "%%   passive clauses  %d\n" num_passive
  and print_gc () =
    let stats = Gc.stat () in
    Printf.printf "%% GC: minor words %.0f; major_words: %.0f; max_heap: %d; minor collections %d; major collections %d\n"
      stats.Gc.minor_words stats.Gc.major_words stats.Gc.top_heap_words stats.Gc.minor_collections stats.Gc.major_collections
  in
  print_gc ();
  print_hashcons_stats "terms" (T.stats ());
  print_hashcons_stats "clauses" (C.stats ());
  print_state_stats (PS.stats state)

(** print the final state to given file in DOT, with
    clauses in result if needed *)
let print_state ?name filename (state, result) =
  let state = match result with
    | Sat.Unsat c ->
      let active = PS.add_active state.PS.active_set c in (* put empty clause in state *)
      {state with PS.active_set = active}
    | _ -> state in
  PS.pp_dot_file ?name filename state

(** setup an alarm for abrupt stop *)
let setup_alarm timeout =
  let handler s =
    begin
      Printf.printf "%% SZS Status ResourceOut\n";
      Unix.kill (Unix.getpid ()) Sys.sigterm
    end
  in
  ignore (Sys.signal Sys.sigalrm (Sys.Signal_handle handler));
  Unix.alarm (max 1 (int_of_float timeout))

(** setup output format and details *)
let setup_output params =
  (match params.param_output_syntax with
  | "tstp" ->
    C.pp_clause := C.pp_clause_tstp;
    T.pp_term := T.pp_term_tstp;
    C.pp_proof := C.pp_proof_tstp
  | "debug" ->
    C.pp_clause := C.pp_clause_debug;
    T.pp_term := (T.pp_term_debug :> T.pprinter_term);
    C.pp_proof := C.pp_proof_debug
  | s -> failwith ("unknown output syntax " ^ s));
  (if params.param_print_sort
    then T.pp_term_debug#sort true);
  (if params.param_print_all
    then begin T.pp_term_debug#skip_lambdas false; T.pp_term_debug#skip_db false end);
  Format.printf "%% format: %s, print sort: %B, print all: %B@." params.param_output_syntax
    params.param_print_sort params.param_print_all

let () =
  Random.init !seed;
  (* parse arguments *)
  let params = parse_args () in
  (if params.param_version then (Format.printf "%% zipperposition v%s@." version; raise Exit));
  let steps = if params.param_steps = 0
    then None else (Format.printf "%% run for %d steps@." params.param_steps;
                    Some params.param_steps)
  and timeout = if params.param_timeout = 0.
    then None else (Format.printf "%% run for %f s@." params.param_timeout;
                    ignore (setup_alarm params.param_timeout);
                    Some (Unix.gettimeofday() +. params.param_timeout -. 0.25))
  and progress = params.param_progress in
  (* setup printing *)
  setup_output params;
  (* parse file *)
  let f = List.hd params.param_files in
  Printf.printf "%% process file %s\n" f;
  let clauses = parse_file ~recursive:true f in
  Printf.printf "%% parsed %d clauses\n" (List.length clauses);
  (* find the calculus *)
  let calculus = match params.param_calculus with
    | "superposition" -> Sup.superposition
    | "delayed" -> Delayed.delayed
    | x -> failwith ("unknown calculus "^x)
  in
  (* first preprocessing, with a simple ordering. *)
  let clauses = calculus#preprocess ~ord:(O.default_ordering ()) ~select:no_select clauses in
  Utils.debug 2 (lazy (Utils.sprintf "%% clauses first-preprocessed into: @[<v>%a@]@."
                 (Utils.pp_list ~sep:"" !C.pp_clause#pp_h) clauses));
  (* XXX detect some axioms *)
  let clauses =
    if params.param_theories then
      let axioms = Theories.detect_total_relations ~ord:(O.default_ordering ()) clauses in
      List.rev_append axioms clauses
    else clauses
  in
  (* choose an ord now, using clauses *)
  let ord_factory = match params.param_ord with
    | "rpo" -> O.rpo
    | "rpo6" -> O.rpo6
    | "kbo" -> O.kbo
    | x -> failwith ("unknown ordering " ^ x) in
  let so = if params.param_precedence
    then Precedence.heuristic_precedence ord_factory (calculus#constr clauses) clauses
    else Precedence.make_ordering (Precedence.compose_constraints
                                   Precedence.alpha_constraint (calculus#constr clauses)) in
  let ord = ord_factory so in
  Format.printf "%% signature: %a@." T.pp_signature ord#symbol_ordering#signature;
  (* indexing *)
  setup_index params.param_index;
  (* selection function *)
  Format.printf "%% selection function: %s@." params.param_select;
  let select = Sel.selection_from_string ~ord params.param_select in
  (* preprocess clauses (including calculus axioms), then possibly simplify them *)
  let clauses = List.rev_append calculus#axioms clauses in
  let num_clauses = List.length clauses in
  let clauses = calculus#preprocess ~ord ~select clauses in
  List.iter (C.check_ord_hclause ~ord) clauses;
  let clauses = if params.param_presimplify
    then Sat.initial_simplifications ~ord ~calculus ~select clauses
    else clauses in
  Utils.debug 1 (lazy (Utils.sprintf "%% %d clauses processed into: @[<v>%a@]@."
                 num_clauses (Utils.pp_list ~sep:"" !C.pp_clause#pp_h) clauses));
  (* create a state, with clauses added to passive_set and axioms to set of support *)
  let state = PS.mk_state ~ord params in
  let state = {state with PS.passive_set=PS.add_passives state.PS.passive_set clauses} in
  (* saturate *)
  let state, result, num = Sat.given_clause ?steps ?timeout ~progress ~calculus state
  in
  Printf.printf "%% ===============================================\n";
  Printf.printf "%% done %d iterations\n" num;
  print_stats state;
  Sup.print_stats ();
  Format.printf "%% final signature: %a@." T.pp_signature ord#symbol_ordering#signature;
  (match params.param_dot_file with (* print state *)
  | None -> ()
  | Some dot_f -> print_state ~name:("\""^f^"\"") dot_f (state, result));
  match result with
  | Sat.Unknown | Sat.Timeout -> Printf.printf "%% SZS status ResourceOut\n"
  | Sat.Error s -> Printf.printf "%% error occurred: %s\n" s
  | Sat.Sat ->
      Printf.printf "%% SZS status CounterSatisfiable\n";
      Utils.debug 1 (lazy (Utils.sprintf "%% saturated set: @[<v>%a@]@."
                     C.pp_set state.PS.active_set.PS.active_clauses))
  | Sat.Unsat c ->
      (* print status then proof *)
      Printf.printf "# SZS status Theorem\n";
      if params.param_proof
        then Format.printf ("@.# SZS output start Refutation@.@[<v>%a@]@." ^^
                          "# SZS output end Refutation@.") !C.pp_proof#pp c
        else ()

let _ =
  at_exit (fun () -> 
    Printf.printf "\n%% run time: %.3f\n" (Sat.get_total_time ()))
