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

open Basic
open Symbols

module T = Terms
module C = Clauses
module Utils = FoUtils

let prof_rpo = Utils.mk_profiler "compare_rpo"
let prof_rpo6 = Utils.mk_profiler "compare_rpo6"
let prof_kbo = Utils.mk_profiler "compare_kbo"

(* ----------------------------------------------------------------------
 * module interface for orderings, internal (used to create the different classes)
 * ---------------------------------------------------------------------- *)

module type S =
  sig
    (* This order relation should be:
     * - stable for instantiation
     * - monotonic
     * - total on ground terms *)
    val compare_terms : prec:precedence -> term -> term -> comparison

    val name : string
  end

module KBO = struct
  let name = "kbo"

  let eq_term = T.eq_term

  (** used to keep track of the balance of variables *)
  type var_balance = {
    offset : int;
    mutable pos_counter : int;
    mutable neg_counter : int;
    balance : int array;
  }

  (** create a balance for the two terms *)
  let mk_balance t1 t2 =
    if T.is_ground_term t1 && T.is_ground_term t2
      then
        { offset = 0; pos_counter = 0; neg_counter = 0; balance = Obj.magic None }
      else begin
        let vars = T.vars_list [t1; t2] in
        let minvar, maxvar = T.min_var vars, T.max_var vars in
        assert (minvar <= maxvar);
        let width = maxvar - minvar + 1 in  (* width between min var and max var *)
        let vb = {
          offset = minvar; (* offset of variables to 0 *)
          pos_counter = 0;
          neg_counter = 0;
          balance = Array.make width 0;
        } in
        Obj.set_tag (Obj.repr vb.balance) Obj.no_scan_tag;  (* no GC scan *)
        vb
      end

  (** add a positive variable *)
  let add_pos_var balance idx =
    let idx = idx - balance.offset in
    let n = balance.balance.(idx) in
    (if n = 0
      then balance.pos_counter <- balance.pos_counter + 1
      else if n = -1 then balance.neg_counter <- balance.neg_counter - 1);
    balance.balance.(idx) <- n + 1

  (** add a negative variable *)
  let add_neg_var balance idx =
    let idx = idx - balance.offset in
    let n = balance.balance.(idx) in
    (if n = 0
      then balance.neg_counter <- balance.neg_counter + 1
      else if n = 1 then balance.pos_counter <- balance.pos_counter - 1);
    balance.balance.(idx) <- n - 1

  (** the KBO ordering itself. The implementation is borrowed from
      the kbo_5 version of "things to know when implementing KBO".
      It should be linear time. *)
  let rec kbo ~prec t1 t2 =
    let balance = mk_balance t1 t2 in
    (** variable balance, weight balance, t contains variable y. pos
        stands for positive (is t the left term) *)
    let rec balance_weight wb t y pos =
      match t.term with
      | Var x ->
        if pos
          then (add_pos_var balance x; (wb + 1, x = y))
          else (add_neg_var balance x; (wb - 1, x = y))
      | Bind (s, _, t') ->
        let wb' = if pos then wb + prec.prec_weight s else wb - prec.prec_weight s in
        balance_weight wb' t' y pos
      | BoundVar _ -> (if pos then wb + 1 else wb - 1), false
      | Node (s, l) ->
        let wb' = if pos then wb + prec.prec_weight s else wb - prec.prec_weight s in
        balance_weight_rec wb' l y pos false
    (** list version of the previous one, threaded with the check result *)
    and balance_weight_rec wb terms y pos res = match terms with
      | [] -> (wb, res)
      | t::terms' ->
        let (wb', res') = balance_weight wb t y pos in
        balance_weight_rec wb' terms' y pos (res || res')
    (** lexicographic comparison *)
    and tckbolex wb terms1 terms2 =
      match terms1, terms2 with
      | [], [] -> wb, Eq
      | t1::terms1', t2::terms2' ->
        (match tckbo wb t1 t2 with
        | (wb', Eq) -> tckbolex wb' terms1' terms2'
        | (wb', res) -> (* just compute the weights and return result *)
          let wb'', _ = balance_weight_rec wb' terms1' 0 true false in
          let wb''', _ = balance_weight_rec wb'' terms2' 0 false false in
          wb''', res)
      | [], _ | _, [] -> failwith "different arities in lexicographic comparison"
    (** commutative comparison. Not linear, must call kbo to
        avoid breaking the weight computing invariants *)
    and tckbocommute wb ss ts =
      (* multiset comparison *)
      let res = Utils.multiset_partial (kbo ~prec) ss ts in
      (* also compute weights of subterms *)
      let wb', _ = balance_weight_rec wb ss 0 true false in
      let wb'', _ = balance_weight_rec wb' ts 0 false false in
      wb'', res
    (** tupled version of kbo (kbo_5 of the paper) *)
    and tckbo wb t1 t2 =
      match t1.term, t2.term with
      | _ when T.eq_term t1 t2 -> (wb, Eq) (* do not update weight or var balance *)
      | Var x, Var y ->
        add_pos_var balance x;
        add_neg_var balance y;
        (wb, Incomparable)
      | Var x,  _ ->
        add_pos_var balance x;
        let wb', contains = balance_weight wb t2 x false in
        (wb' + 1, if contains then Lt else Incomparable)
      |  _, Var y -> 
        add_neg_var balance y;
        let wb', contains = balance_weight wb t1 y true in
        (wb' - 1, if contains then Gt else Incomparable)
      (* node/node, De Bruijn/De Bruijn, Bind/Bind *)
      | Node (f, ss), Node (g, ts) -> tckbo_composite wb f g ss ts
      | Bind (f, _, t1'), Bind (g, _, t2') -> tckbo_composite wb f g [t1'] [t2']
      | BoundVar i, BoundVar j ->
        (wb, if i = j && t1.sort == t2.sort then Eq else Incomparable)
      (* node and something else *)
      | Node (f, ss), Bind (g, _, t2') -> tckbo_composite wb f g ss [t2']
      | Node (f, ss), BoundVar _ -> tckbo_composite wb f db_symbol ss []
      | Bind (f, _, t1'), Node (g, ts) -> tckbo_composite wb f g [t1'] ts
      | BoundVar _, Node (g, ts) -> tckbo_composite wb db_symbol g [] ts
      (* De Bruijn with Bind *)
      | Bind (f, _, t1'), BoundVar _ -> tckbo_composite wb f db_symbol [t1'] []
      | BoundVar _, Bind (g, _, t2') -> tckbo_composite wb db_symbol g [] [t2']
    (** tckbo, for composite terms (ie non variables). It takes a symbol
        and a list of subterms. *)
    and tckbo_composite wb f g ss ts =
      (* do the recursive computation of kbo *)
      let wb', recursive = tckbo_rec wb f g ss ts in
      let wb'' = wb' + prec.prec_weight f - prec.prec_weight g in
      (* check variable condition *)
      let g_or_n = if balance.neg_counter = 0 then Gt else Incomparable
      and l_or_n = if balance.pos_counter = 0 then Lt else Incomparable in
      (* lexicographic product of weight and precedence *)
      if wb'' > 0 then wb'', g_or_n
      else if wb'' < 0 then wb'', l_or_n
      else (match prec.prec_compare f g with
        | n when n > 0 -> wb'', g_or_n
        | n when n < 0 ->  wb'', l_or_n
        | _ ->
          assert (List.length ss = List.length ts);
          if recursive = Eq then wb'', Eq
          else if recursive = Lt then wb'', l_or_n
          else if recursive = Gt then wb'', g_or_n
          else wb'', Incomparable)
    (** recursive comparison *)
    and tckbo_rec wb f g ss ts =
      if f = g
        then if has_attr attr_multiset f
          (* use multiset or lexicographic comparison *)
          then tckbocommute wb ss ts
          else tckbolex wb ss ts
        else
          (* just compute variable and weight balances *)
          let wb', _ = balance_weight_rec wb ss 0 true false in
          let wb'', _ = balance_weight_rec wb' ts 0 false false in
          wb'', Incomparable
    in
    let _, res = tckbo 0 t1 t2 in res  (* ignore the weight *)

  let compare_terms ~prec x y =
    Utils.enter_prof prof_kbo;
    let cmp = kbo ~prec x y in
    Utils.exit_prof prof_kbo;
    cmp
end

(** hopefully more efficient (polynomial) implementation of LPO,
    following the paper "things to know when implementing LPO" by Löchner.
    We adapt here the implementation clpo6 with some multiset symbols (=) *)
module RPO6 = struct
  let name = "rpo6"

  (** recursive path ordering *)
  let rec rpo6 ~prec s t =
    if T.eq_term s t then Eq else  (* equality test is cheap *)
    match s.term, t.term with
    | Var _, Var _ -> Incomparable
    | _, Var _ -> if T.var_occurs t s then Gt else Incomparable
    | Var _, _ -> if T.var_occurs s t then Lt else Incomparable
    (* node/node, De Bruijn/De Bruijn, Bind/Bind *)
    | Node (f, ss), Node (g, ts) -> rpo6_composite ~prec s t f g ss ts
    | Bind (f, _, s'), Bind (g, _, t') -> rpo6_composite ~prec s t f g [s'] [t']
    | BoundVar i, BoundVar j ->
      if i = j && s.sort == t.sort then Eq else Incomparable
    (* node and something else *)
    | Node (f, ss), Bind (g, _, t') -> rpo6_composite ~prec s t f g ss [t']
    | Node (f, ss), BoundVar _ -> rpo6_composite ~prec s t f db_symbol ss []
    | Bind (f, _, s'), Node (g, ts) -> rpo6_composite ~prec s t f g [s'] ts
    | BoundVar _, Node (g, ts) -> rpo6_composite ~prec s t db_symbol g [] ts
    (* De Bruijn with Bind *)
    | Bind (f, _, s'), BoundVar _ -> rpo6_composite ~prec s t f db_symbol [s'] []
    | BoundVar _, Bind (g, _, t') -> rpo6_composite ~prec s t db_symbol g [] [t']
  (* handle the composite cases *)
  and rpo6_composite ~prec s t f g ss ts =
    match prec.prec_compare f g with
    | 0 when has_attr attr_multiset f ->
      cMultiset ~prec ss ts (* multiset subterm comparison *)
    | 0 ->
      cLMA ~prec s t ss ts  (* lexicographic subterm comparison *)
    | n when n > 0 -> cMA ~prec s ts
    | n when n < 0 -> Utils.not_partial (cMA ~prec t ss)
    | _ -> assert false  (* match exhaustively *)
  (** try to dominate all the terms in ts by s; but by subterm property
      if some t' in ts is >= s then s < t=g(ts) *)
  and cMA ~prec s ts = match ts with
    | [] -> Gt
    | t::ts' ->
      (match rpo6 ~prec s t with
      | Gt -> cMA ~prec s ts'
      | Eq | Lt -> Lt
      | Incomparable -> Utils.not_partial (alpha ~prec ts' s))
  (** lexicographic comparison of s=f(ss), and t=f(ts) *)
  and cLMA ~prec s t ss ts = match ss, ts with
    | si::ss', ti::ts' ->
      (match rpo6 ~prec si ti with
        | Eq -> cLMA ~prec s t ss' ts'
        | Gt -> cMA ~prec s ts' (* just need s to dominate the remaining elements *)
        | Lt -> Utils.not_partial (cMA ~prec t ss')
        | Incomparable -> cAA ~prec s t ss' ts'
      )
    | [], [] -> Eq
    | _ -> assert false (* different length... *)
  (** multiset comparison of subterms (not optimized) *)
  and cMultiset ~prec ss ts = Utils.multiset_partial (rpo6 ~prec) ss ts
  (** bidirectional comparison by subterm property (bidirectional alpha) *)
  and cAA ~prec s t ss ts =
    match alpha ~prec ss t with
    | Gt -> Gt
    | Incomparable -> Utils.not_partial (alpha ~prec ts s)
    | _ -> assert false
  (** if some s in ss is >= t, then s > t by subterm property and transitivity *)
  and alpha ~prec ss t = match ss with
    | [] -> Incomparable
    | s::ss' ->
      (match rpo6 ~prec s t with
       | Eq | Gt -> Gt
       | Incomparable | Lt -> alpha ~prec ss' t)

  let compare_terms ~prec x y =
    Utils.enter_prof prof_rpo6;
    let cmp = rpo6 ~prec x y in
    Utils.exit_prof prof_rpo6;
    cmp
end

(* ----------------------------------------------------------------------
 * ordering records
 * ---------------------------------------------------------------------- *)

(** Check that new_prec is a compatible superset of old_prec *)
let check_precedence old_prec new_prec =
  Utils.debug 3 "check compatibility of @[<h>%a@] with @[<h>%a@]"
                pp_precedence old_prec.prec_snapshot
                pp_precedence new_prec.prec_snapshot;
  let rec check l = match l with
  | [] | [_] -> true
  | x::((y::_) as l') -> new_prec.prec_compare x y > 0 && check l'
  in check old_prec.prec_snapshot

let kbo (prec : precedence) : ordering =
  let cache = T.T2Cache.create 4096 in
  let rec mk_ord prec =
    let compare a b = KBO.compare_terms ~prec:prec a b in
    let ord_compare a b = T.T2Cache.with_cache cache compare a b in
    let ord_set_precedence prec' =
      assert (check_precedence prec prec');
      mk_ord prec'
    in
    { ord_name = "kbo";
      ord_compare;
      ord_clear_cache = (fun () -> T.T2Cache.clear cache);
      ord_precedence = prec;
      ord_set_precedence;
    }
  in mk_ord prec

let rpo6 (prec : precedence) : ordering =
  let cache = T.T2Cache.create 4096 in
  let rec mk_ord prec =
    let compare a b = RPO6.compare_terms ~prec:prec a b in
    let ord_compare a b = T.T2Cache.with_cache cache compare a b in
    let ord_set_precedence prec' =
      assert (check_precedence prec prec');
      mk_ord prec'
    in
    { ord_name = "rpo6";
      ord_compare;
      ord_clear_cache = (fun () -> T.T2Cache.clear cache);
      ord_precedence = prec;
      ord_set_precedence;
    }
  in mk_ord prec

let choose name prec =
  match name with
  | "rpo6" -> rpo6 prec
  | "kbo" -> kbo prec
  | _ -> failwith ("unknown ordering: " ^ name)

let default_ordering signature = rpo6 (Precedence.default_precedence signature)

let no_ordering =
  let rec ord =
    { ord_name = "no_ord";
      ord_compare = (fun t1 t2 -> if t1 == t2 then Eq else Incomparable);
      ord_set_precedence = (fun _ -> ord);
      ord_precedence = Precedence.default_precedence empty_signature;
      ord_clear_cache = (fun () -> ());
    } in
  ord
