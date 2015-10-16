
(*
Zipperposition: a functional superposition prover for prototyping
Copyright (c) 2013, Simon Cruanes
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.  Redistributions in binary
form must reproduce the above copyright notice, this list of conditions and the
following disclaimer in the documentation and/or other materials provided with
the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*)

(** {1 Priority Queue of clauses} *)

(** Heuristic selection of clauses, using queues. Note that some
    queues do not need accept all clauses, as long as one of them does
    (for completeness). Anyway, a fifo queue should always be present,
    and presents this property. *)

open Logtk

module O = Ordering
module Lit = Literal
module Lits = Literals

module type S = ClauseQueue_intf.S

let _profile = ref "default"
let profile () = !_profile
let set_profile s = _profile := s

let () =
  Params.add_opts
    [ "-clause-queue"
    , Arg.String set_profile
    , " choose which set of clause queues to use \
      (for selecting next active clause): choices: default,bfs,explore,ground"
    ]

module Make(C : Clause.S) = struct
  module C = C

  (* weight of a term [t], using the precedence's weight *)
  let term_weight t = FOTerm.size t

  (** {6 Weight functions} *)
  module WeightFun = struct
    type t = C.t -> int

    let weight_lits_ l =
      Array.fold_left
        (fun acc lit -> acc + Lit.heuristic_weight term_weight lit)
        0 l

    let default c =
      (* maximum depth of types. Avoids reasoning on list (list (list .... (list int))) *)
      let _depth_ty =
        Lits.Seq.terms (C.lits c)
        |> Sequence.map FOTerm.ty
        |> Sequence.map Type.depth
        |> Sequence.max ?lt:None
        |> CCOpt.maybe CCFun.id 0
      in
      let trail = C.get_trail c in
      let w_lits = weight_lits_ (C.lits c) in
      let w_trail = C.Trail.fold
        (fun acc t -> match C.Ctx.BoolLit.extract_exn (C.Ctx.BoolLit.abs t) with
          | C.Ctx.BoolLit.Clause_component lits -> acc + weight_lits_ lits
          | C.Ctx.BoolLit.Form f -> acc + Formula.FO.weight f
          | C.Ctx.BoolLit.Ctx (c,_,_) -> acc + weight_lits_ (ClauseContext.raw_lits c)
          | C.Ctx.BoolLit.Case (_,_) ->
              acc + 10 (* generic penalty for each inductive hypothesis *)
          | C.Ctx.BoolLit.Name _
          | C.Ctx.BoolLit.Input  -> acc (* mere markers *)
        ) 0 trail 
      in
      w_lits * Array.length (C.lits c) + w_trail * (C.Trail.length trail) + _depth_ty

    let age c =
      if C.is_empty c then 0
      else C.id c

    let _conjecture_threshold = 15

    let favor_conjecture c =
      if C.is_empty c then 0
      else
        let d = match C.distance_to_conjecture c with
          | Some d -> min d _conjecture_threshold
          | None -> _conjecture_threshold
        in
        1+d

    let combine ws =
      assert (ws <> []);
      assert (List.for_all (fun (_,c) -> c > 0) ws);
      fun c ->
        List.fold_left
          (fun sum (w,coeff) -> coeff * w c)
          0 ws
  end

  module H = CCHeap.Make(struct
    type t = (int * C.t)
    let leq (i1, c1) (i2, c2) = i1 <= i2 || (i1 = i2 && C.id c1 <= C.id c2)
  end)

  type t = {
    heap : H.t;
    functions : functions;
  } (** A priority queue of clauses, purely functional *)
  and functions = {
    weight : C.t -> int;
    accept : C.t -> bool;
    name : string;
  }

  (** generic clause queue based on some ordering on clauses, given
      by a weight function *)
  let mk_queue ?(accept=(fun _ -> true)) ~weight name =
    let functions = {
      weight;
      accept;
      name;
    } in
    { heap = H.empty; functions; }

  let is_empty q =
    H.is_empty q.heap

  let add q c =
    if q.functions.accept c
      then
        let w = q.functions.weight c in
        let heap = H.insert (w, c) q.heap in
        { q with heap; }
      else q

  let adds q hcs =
    let heap =
      Sequence.fold
        (fun heap c ->
          if q.functions.accept c
            then
              let w = q.functions.weight c in
              H.insert (w,c) heap
            else heap)
        q.heap hcs in
    { q with heap; }

  let take_first q =
    (if is_empty q then raise Not_found);
    let new_h, (_, c) = H.take_exn q.heap in
    let q' = { q with heap=new_h; } in
    q', c

  (** Keep only the clauses that are in the set *)
  let clean q set =
    let new_heap = H.filter (fun (_, c) -> C.CSet.mem set c) q.heap in
    { q with heap=new_heap; }

  let name q = q.functions.name

  let fifo =
    let name = "fifo_queue" in
    mk_queue ~weight:(fun c -> C.id c) name

  let clause_weight =
    let name = "clause_weight" in
    mk_queue ~weight:WeightFun.default name

  let goals =
    (* check whether a literal is a goal *)
    let is_goal_lit lit = Lit.is_neg lit in
    let is_goal_clause c = CCArray.for_all is_goal_lit (C.lits c) in
    let name = "prefer_goals" in
    mk_queue ~accept:is_goal_clause ~weight:WeightFun.default name

  let ground =
    let name = "prefer_ground" in
    mk_queue ~accept:C.is_ground ~weight:WeightFun.default name

  let non_goals =
    (* check whether a literal is a goal *)
    let is_goal_lit lit = Lit.is_neg lit in
    let is_non_goal_clause c = CCArray.for_all
      (fun x -> not (is_goal_lit x))
      (C.lits c) in
    let name = "prefer_non_goals" in
    mk_queue ~accept:is_non_goal_clause ~weight:WeightFun.default name

  let pos_unit_clauses =
    let is_unit_pos c = match C.lits c with
    | [| lit |] when Lit.is_pos lit -> true
    | _ -> false
    in
    let name = "prefer_pos_unit_clauses" in
    mk_queue ~accept:is_unit_pos ~weight:WeightFun.default name

  let horn =
    let accept c = Lits.is_horn (C.lits c) in
    let name = "prefer_horn" in
    mk_queue ~accept ~weight:WeightFun.default name

  let lemmas =
    let name = "lemmas" in
    let accept c = C.get_flag C.flag_lemma c in
    (* use a fifo on lemmas *)
    mk_queue ~accept ~weight:WeightFun.default name

  let goal_oriented =
    let weight = WeightFun.(combine [age, 1; default, 4; favor_conjecture, 1]) in
    let name = "goal_oriented" in
    let accept _ = true in
    mk_queue ~accept ~weight name

  (** {6 Combination of queues} *)

  type queues = (t * int) list

  module Profiles = struct
    let bfs =
      [ fifo, 5
      ; clause_weight, 1
      ]

    let explore =
      [ fifo, 1
      ; clause_weight, 4
      ; goals, 1
      ]

    let ground =
      [ fifo, 1
      ; pos_unit_clauses, 1
      ; ground, 2
      ]

    let why3 =
      [ goal_oriented, 3
      ; fifo, 1
      ]
  end

  let default_queues =
    match !_profile with
    | "default" ->
        [ fifo, 4
        ; clause_weight, 3
        ; goals, 1
        ; pos_unit_clauses, 1
        ]
    | "bfs" -> Profiles.bfs
    | "explore" -> Profiles.explore
    | "ground" -> Profiles.ground
    | "why3" -> Profiles.why3
    | n -> failwith ("no such profile: " ^ n)

  let pp buf q =
    Printf.bprintf buf "queue %s" (name q)

  let to_string q =
    let buf = Buffer.create 15 in
    pp buf q;
    Buffer.contents buf

  let pp_list buf qs =
    let pp_pair buf (c, i) = Printf.bprintf buf "%a (w=%d)" pp c i in
    Buffer.add_char buf '[';
    Util.pp_list pp_pair buf qs;
    Buffer.add_char buf ']';
    ()

  let fmt fmt q =
    Format.pp_print_string fmt (to_string q)

  let fmt_list out qs =
    let fmt_pair out (c, i) = Format.fprintf out "%a (w=%d)" fmt c i in
    CCList.print ~start:"[" ~stop:"]" fmt_pair out qs;
    ()
end
