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

(** {1 The state of a proof, contains a set of active clauses (processed),
    a set of passive clauses (to be processed), and an ordering
    that is used for redundancy elimination.} *)

open Logtk
open Comparison.Infix

module T = Term
module C = Clause
module S = Substs
module Lit = Literal
module Pos = Position
module BV = Bitvector
module CQ = ClauseQueue

type clause_pos = C.t * Pos.t * T.t

module TermIndex = Fingerprint.Make(struct
  type t = clause_pos
  let compare (c1, p1, t1) (c2, p2, t2) =
    Util.lexicograph_combine [C.compare c1 c2; Pos.compare p1 p2; T.compare t1 t2]
end)

module UnitIndex = Dtree.Make(struct
  type t = C.t
  let equal = C.eq
  let extract c = match c.C.hclits with
    | [| Literal.Equation (l, r, sign, _) |] -> l, r, sign
    | _ -> assert false
  let priority _ = 1
end)

module SubsumptionIndex = FeatureVector.Make(struct
  type t = C.t
  let cmp = C.compare
  let iter c f =
    Array.iter
      (fun lit -> match lit with Literal.Equation (l, r, sign, _) -> f l r sign)
      c.C.hclits
end)

let stat_passive_cleanup = Util.mk_stat "cleanup of passive set"

(* XXX: no customization of indexing for now
let _indexes =
  let table = Hashtbl.create 2 in
  (* TODO write a Substitution Tree, with the new substitution representation? *)
  (* TODO rewrite a general purpose discrimination tree *)
  let mk_fingerprint fp = 
    Fingerprint.mk_index ~cmp:Clauses.compare_clause_pos fp in
  Hashtbl.add table "fp" (mk_fingerprint Fingerprint.fp6m);
  Hashtbl.add table "fp7m" (mk_fingerprint Fingerprint.fp7m);
  Hashtbl.add table "fp16" (mk_fingerprint Fingerprint.fp16);
  table
*)

(** {2 Utils (for indexing part of a clause)} *)

(* apply the operation to literals that verify (eligible c i lit) where
   i is the index of the literal; if subterm is true then the operation is
   done on every subterm, otherwise on root *)
let update_with_clause op acc eligible ~subterms ~both_sides c =
  let acc = ref acc in
  (* specialize eligible for the clause *)
  let eligible = eligible c in
  (* process a lit *)
  let rec process_lit op acc i = function
    | Lit.Equation (l,r,_,_) when both_sides ->
      let acc = process_term op acc l [Position.left_pos; i] in
      process_term op acc r [Position.right_pos; i]
    | Lit.Equation (l,r,_,Gt) ->
      process_term op acc l [Position.left_pos; i]
    | Lit.Equation (l,r,_,Lt) ->
      process_term op acc r [Position.right_pos; i]
    | Lit.Equation (l,r,_,Incomparable)
    | Lit.Equation (l,r,_,Eq) ->
      let acc = process_term op acc l [Position.left_pos; i] in
      process_term op acc r [Position.right_pos; i]
  (* process a term (maybe recursively). We build positions in the wrong order,
     so we have to reverse them before giving them to [op acc]. *)
  and process_term op acc t pos =
    match t.T.term with
    | T.Var _ | T.BoundVar _ -> acc  (* variables are never indexed *)
    | T.Bind (s, t') ->
      (* apply the operation on the term itself *)
      let acc = op acc t (c, List.rev pos, t) in
      if subterms then process_term op acc t' (0::pos) else acc
    | T.Node (_, []) -> op acc t (c, List.rev pos, t)
    | T.Node (_, l) ->
      (* apply the operation on the term itself *)
      let acc = op acc t (c, List.rev pos, t) in
      if subterms
        then (* recursively process (non-var) subterms *)
          let _, acc = List.fold_left
            (fun (i, acc) t -> i+1, process_term op acc t (i::pos))
            (0, acc) l
          in acc
        else acc (* stop after the root literal *)
    | T.At (t1, t2) ->
      let acc = op acc t (c, List.rev pos, t) in
      if subterms
        then
          let acc = process_term op acc t1 (0::pos) in
          process_term op acc t2 (1::pos)
        else acc
  in
  (* process eligible literals *)
  Array.iteri
    (fun i lit -> if eligible i lit then acc := process_lit op !acc i lit)
    c.C.hclits;
  !acc

(* update acc using op, on all given clauses *)
let update_with_clauses op acc eligible ~subterms ~both_sides cs =
  let acc = ref acc in
  Sequence.iter
    (fun c -> acc := update_with_clause op !acc eligible ~subterms ~both_sides c)
    cs;
  !acc

(* process literals that are potentially eligible for resolution *)
let eligible_res c =
  let bv = C.eligible_res (c,0) S.empty in
  fun i lit -> BV.get bv i

(* process literals that are potentially eligible for paramodulation *)
let eligible_param c =
  let bv = C.eligible_param (c,0) S.empty in
  fun i lit -> BV.get bv i

(* process all literals *)
let eligible_always c i lit = true

(** {2 Set of active clauses} *)

module ActiveSet = struct
  type t = 
    < ctx : Clause.context;
      clauses : Clause.CSet.t;          (** set of active clauses *)
      idx_sup_into : TermIndex.t;       (** index for superposition into the set *)
      idx_sup_from : TermIndex.t;       (** index for superposition from the set *)
      idx_back_demod : TermIndex.t;     (** index for backward demodulation/simplifications *)
      idx_fv : SubsumptionIndex.t;      (** index for subsumption *)

      add : Clause.t Sequence.t -> unit;   (** add clauses *)
      remove : Clause.t Sequence.t -> unit;(** remove clauses *)
    >

  let create ~ctx signature =
    (* create a FeatureVector index from the current signature *)
    let idx = SubsumptionIndex.of_signature signature in
    (object (self)
      val mutable m_clauses = C.CSet.empty
      val mutable m_sup_into = TermIndex.empty
      val mutable m_sup_from = TermIndex.empty
      val mutable m_back_demod = TermIndex.empty
      val mutable m_fv = idx
      method ctx = ctx
      method clauses = m_clauses
      method idx_sup_into = m_sup_into
      method idx_sup_from = m_sup_from
      method idx_back_demod = m_back_demod
      method idx_fv = m_fv

      (** update indexes by removing/adding clauses *)
      method update op cs =
        (* sup into: subterms of literals that are eligible for res *)
        m_sup_into <-
          update_with_clauses op m_sup_into eligible_res ~subterms:true ~both_sides:false cs;
        (* sup from : literals that are eligible for param *)
        m_sup_from <-
          update_with_clauses op m_sup_from eligible_param ~subterms:false ~both_sides:false cs;
        (* back-demod : all subterms *)
        m_back_demod <-
          update_with_clauses op m_back_demod eligible_always ~subterms:true ~both_sides:true cs

      (** add clauses (only process the ones not present in the set) *)
      method add cs =
        let cs = Sequence.filter (fun c -> not (C.CSet.mem m_clauses c)) cs in
        let cs = Sequence.persistent cs in
        m_clauses <- C.CSet.of_seq m_clauses cs;
        let op tree = TermIndex.add tree in
        self#update op cs;
        m_fv <- SubsumptionIndex.add_seq m_fv cs

      (** remove clauses (only process the ones present in the set) *)
      method remove cs =
        let cs = Sequence.filter (C.CSet.mem m_clauses) cs in
        let cs = Sequence.persistent cs in
        m_clauses <- C.CSet.remove_seq m_clauses cs;
        let op tree = TermIndex.remove tree in
        self#update op cs;
        m_fv <- SubsumptionIndex.remove_seq m_fv cs
    end :> t)
end

(** {2 Set of simplifying (unit) clauses} *)

module SimplSet = struct
  type t =
    < ctx : Clause.context;
      idx_simpl : UnitIndex.t;      (** index for forward simplifications *)

      add : Clause.t Sequence.t -> unit;
      remove : Clause.t Sequence.t -> unit;
    >

  (** Create a simplification set *)
  let create ~ctx =
    object
      val mutable m_simpl = UnitIndex.empty
      method ctx = ctx
      method idx_simpl = m_simpl

      method add cs =
        m_simpl <- UnitIndex.add_seq m_simpl cs

      method remove cs =
        m_simpl <- UnitIndex.remove_seq m_simpl cs
    end
end

(** {2 Set of passive clauses} *)

module PassiveSet = struct
  type t =
    < ctx : Clause.context;
      clauses : Clause.CSet.t;           (** set of clauses *)
      queues : (ClauseQueue.t * int) list;

      add : Clause.t Sequence.t -> unit;   (** add clauses *)
      remove : int -> unit;               (** remove clause by ID *)
      next : unit -> Clause.t option;      (** next passive clause, if any *)
      clean : unit -> unit;               (** cleanup internal queues *)
    >

  let create ~ctx queues =
    assert (queues != []);
    let length = List.length queues in
    object
      val mutable m_clauses = C.CSet.empty
      val m_queues = Array.of_list queues
      val mutable m_state = (0,0)
      method ctx = ctx
      method clauses = m_clauses
      method queues = Array.to_list m_queues

      (** add clauses (not already present in set) to the set *)
      method add cs =
        let cs = Sequence.filter (fun c -> not (C.CSet.mem m_clauses c)) cs in
        let cs = Sequence.persistent cs in
        m_clauses <- C.CSet.of_seq m_clauses cs;
        for i = 0 to length - 1 do
          (* add to i-th queue *)
          let (q, w) = m_queues.(i) in
          m_queues.(i) <- (CQ.adds q cs, w)
        done

      (** remove clauses (not from the queues) *)
      method remove id = 
        m_clauses <- C.CSet.remove_id m_clauses id

      (** next clause *)
      method next () =
        let first_idx, w = m_state in
        (* search in the idx-th queue *)
        let rec search idx weight =
          let q, w = m_queues.(idx) in
          if weight >= w || CQ.is_empty q
          then next_idx (idx+1) (* empty queue, go to the next one *)
          else begin
            let new_q, c = CQ.take_first q in (* pop from this queue *)
            m_queues.(idx) <- new_q, w;
            if C.CSet.mem m_clauses c
              then begin (* done, found a still-valid clause *)
                Util.debug 3 "taken clause from %s" (CQ.name q);
                m_clauses <- C.CSet.remove m_clauses c;
                m_state <- (idx, weight+1);
                Some c
              end else search idx weight
          end
        (* search the next non-empty queue *)
        and next_idx idx =
          if idx = first_idx then None (* all queues are empty *)
          else if idx = length then next_idx 0 (* cycle *)
          else search idx 0 (* search in this queue *)
        in
        search first_idx w

      (* cleanup the clause queues *)
      method clean () =
        Util.incr_stat stat_passive_cleanup;
        for i = 0 to length - 1 do
          let q, w = m_queues.(i) in
          m_queues.(i) <- CQ.clean q m_clauses, w
        done
    end
end

(** {2 Proof State} *)

type t =
  < ctx : Clause.context;
    params : Params.t;
    simpl_set : SimplSet.t;              (** index for forward demodulation *)
    active_set : ActiveSet.t;            (** active clauses *)
    passive_set : PassiveSet.t;          (** passive clauses *)
    meta_prover : MetaProverState.t option;
    experts : Experts.Set.t;            (** Set of current experts *)

    add_expert : Experts.t -> unit;     (** Add an expert *)
  >

let create ~ctx ?meta params signature =
  let queues = ClauseQueue.default_queues
  and _experts = ref (Experts.Set.empty ~ctx) in
  object
    val m_active = (ActiveSet.create ~ctx signature :> ActiveSet.t)
    val m_passive = (PassiveSet.create ~ctx queues :> PassiveSet.t)
    val m_simpl = (SimplSet.create ~ctx :> SimplSet.t)
    method ctx = ctx
    method params = params
    method active_set = m_active
    method passive_set = m_passive
    method simpl_set = m_simpl
    method meta_prover = meta
    method experts = !_experts
    method add_expert e =
      let es = Experts.update_ctx e ~ctx in
      _experts := Experts.Set.add_list !_experts es;
      (* add clauses of each expert to the set of passive clauses *)
      let clauses = Sequence.flatMap
        (fun e -> Sequence.of_list (Experts.clauses e))
        (Sequence.of_list es) in
      m_passive#add clauses
  end

type stats = int * int * int (* num passive, num active, num simplification *)

let stats (state : t) =
  ( C.CSet.size state#active_set#clauses
  , C.CSet.size state#passive_set#clauses
  , UnitIndex.size state#simpl_set#idx_simpl)

let pp buf state =
  let num_active, num_passive, num_simpl = stats state in
  Printf.bprintf buf
    "state {%d active clauses; %d passive_clauses; %d simplification_rules; %a}"
    num_active num_passive num_simpl
    CQ.pp_list state#passive_set#queues

let debug buf state =
  let num_active, num_passive, num_simpl = stats state in
  Printf.bprintf buf
    ("state {%d active clauses; %d passive_clauses; %d simplification_rules; %a" ^^
      "\nactive:%a\npassive:%a\n}")
    num_active num_passive num_simpl
    CQ.pp_list state#passive_set#queues
    C.pp_set_debug state#active_set#clauses
    C.pp_set_debug state#passive_set#clauses
