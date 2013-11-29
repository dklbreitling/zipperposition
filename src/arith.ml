
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

(** {6 Arithmetic Manipulations} *)

open Logtk

module S = Symbol
module M = Monome
module Literals = Literal.Arr

let prof_arith_simplify = Util.mk_profiler "arith.simplify"
let prof_arith_extract = Util.mk_profiler "arith.extract"

(** {2 Utils} *)

let is_arith_ty ty =
  Type.eq ty Type.int || Type.eq ty Type.rat || Type.eq ty Type.real

(** {2 Terms} *)

module T = struct
  include FOTerm  (* for the rest of arith *)

  let arith_kind t = match t.term with
    | Node ((S.Int _ | S.Rat _ | S.Real _), _, []) -> `Const
    | Node (s, _, _) when Symbol.Arith.is_arith s -> `Expr
    | Var _
    | BoundVar _ ->
      if is_arith_ty t.ty then `Var else `Not
    | _ -> `Not

  let is_arith t = match arith_kind t with
    | `Const | `Expr | `Var -> true
    | `Not -> false

  let is_arith_const t = match arith_kind t with
    | `Const -> true
    | `Var | `Expr | `Not -> false

  let is_compound_arith t = match arith_kind t with
    | `Expr -> true
    | `Var | `Const | `Not -> false

  let rec sum_list l = match l with
    | [] -> failwith "Arith.sum_list: got empty list"
    | [x] -> x
    | x::l' -> mk_node ~tyargs:[ty x] S.Arith.sum [x; sum_list l']

  (* TODO: simplify on the fly? *)

  let mk_sum t1 t2 = mk_node ~tyargs:[ty t1] S.Arith.sum [t1; t2]
  let mk_difference t1 t2 = mk_node ~tyargs:[ty t1] S.Arith.difference [t1; t2]
  let mk_product t1 t2 = mk_node ~tyargs:[ty t1] S.Arith.product [t1; t2]
  let mk_quotient t1 t2 = mk_node ~tyargs:[ty t1] S.Arith.quotient [t1; t2]
  let mk_uminus t = mk_node ~tyargs:[ty t] S.Arith.uminus [t]

  let mk_remainder_e t s =
    assert (Type.eq (ty t) Type.int);
    mk_node ~tyargs:[Type.int] S.Arith.remainder_e [t; mk_const s]

  let mk_quotient_e t s =
    assert (Type.eq (ty t) Type.int);
    mk_node ~tyargs:[Type.int] S.Arith.quotient_e [t; mk_const s]

  let mk_less t1 t2 =
    if is_arith_const t1 && is_arith_const t2
      then if S.Arith.Op.less (head t1) (head t2)
        then true_term
        else false_term
      else mk_node ~tyargs:[ty t1] S.Arith.less [t1; t2]

  let mk_lesseq t1 t2 =
    if is_arith_const t1 && is_arith_const t2
      then if S.Arith.Op.lesseq (head t1) (head t2)
        then true_term
        else false_term
      else mk_node ~tyargs:[ty t1] S.Arith.lesseq [t1; t2]

  let mk_greater t1 t2 = mk_less t2 t1
  let mk_greatereq t1 t2 = mk_lesseq t2 t1

  let extract_subterms t =
    (* recursive function that gathers terms into set *)
    let rec gather set t = match t.term with
    | Var _
    | BoundVar _ -> Tbl.replace set t ()
    | Node (s, _, []) when S.is_numeric s -> ()
    | Node (s, _, l) when S.Arith.is_arith s ->
      List.iter (gather set) l
    | Node _ -> Tbl.replace set t ()
    in
    if is_arith t
      then
        let set = Tbl.create 5 in
        let () = gather set t in
        Tbl.to_list set
      else []

  let _var_occur_strict v t =
    not (eq v t) && var_occurs v t

  let shielded v t = match extract_subterms t with
    | [] -> _var_occur_strict v t
    | l -> List.exists (fun t' -> _var_occur_strict v t') l

  let flag_simplified = new_flag ()

  (* evaluator for arith *)
  let __ev =
    let e = Evaluator.FO.create () in
    Evaluator.FO.with_arith e;
    e

  let simplify t =
    if get_flag flag_simplified t
      then t
      else begin
        Util.enter_prof prof_arith_simplify;
        let t' = Evaluator.FO.eval __ev t in
        set_flag flag_simplified t' true;
        Util.exit_prof prof_arith_simplify;
        t'
      end
end

(** {2 Formulas} *)

module F = struct
  include FOFormula

  let simplify f =
    map_leaf
      (fun f -> match f.form with
        | Atom p ->
          let p' = T.simplify p in
          mk_atom p'
        | Equal (t1, t2) ->
          let t1' = T.simplify t1 in
          let t2' = T.simplify t2 in
          if T.is_arith_const t1'  && T.is_arith_const t2'
            then if T.eq t1' t2'
              then mk_true
              else mk_false
            else mk_eq t1' t2'
        | _ -> f)
      f
end

(** {2 View a Literal as an arithmetic Literal}. *)

module Lit = struct
  let is_arith lit = match lit with
  | Literal.Equation (l, r, _, _) -> T.is_arith l || T.is_arith r
  | Literal.Prop (p, _) -> T.is_arith p
  | Literal.True
  | Literal.False -> false

  let mk_less t1 t2 =
    Literal.mk_true (T.mk_less t1 t2)

  let mk_lesseq t1 t2 =
    Literal.mk_true (T.mk_lesseq t1 t2)

  let mk_eq ~ord t1 t2 =
    if T.is_arith_const t1 && T.is_arith_const t2
      then if T.eq t1 t2
        then Literal.mk_tauto
        else Literal.mk_absurd
      else Literal.mk_eq ~ord t1 t2

  let mk_neq ~ord t1 t2 =
    if T.is_arith_const t1 && T.is_arith_const t2
      then if T.eq t1 t2
        then Literal.mk_absurd
        else Literal.mk_tauto
      else Literal.mk_neq ~ord t1 t2

  let _uminus = S.Arith.Op.uminus

  (** {3 Single-term literal}
      This type helps deal with the special case where there is a single
      term in the literal. It can therefore perform many simplifications.
      The term is multiplied by a constant (type [coeff], for more readability).
  *)

  module Single = struct
    type t =
    | True
    | False
    | Eq of FOTerm.t * Symbol.t
    | Neq of FOTerm.t * Symbol.t
    | L_less of FOTerm.t * Symbol.t
    | L_lesseq of FOTerm.t * Symbol.t
    | R_less of Symbol.t * FOTerm.t
    | R_lesseq of Symbol.t * FOTerm. t

    let pp buf lit = match lit with
    | True -> Buffer.add_string buf "true"
    | False -> Buffer.add_string buf "false"
    | Eq (t,const) -> Printf.bprintf buf "%a = %a" T.pp t S.pp const
    | Neq (t,const) -> Printf.bprintf buf "%a ≠ %a" T.pp t S.pp const
    | L_less (t,const) -> Printf.bprintf buf "%a < %a" T.pp t S.pp const
    | L_lesseq (t,const) -> Printf.bprintf buf "%a ≤ %a" T.pp t S.pp const
    | R_less (const,t) -> Printf.bprintf buf "%a < %a" S.pp const T.pp t
    | R_lesseq (const,t) -> Printf.bprintf buf "%a ≤ %a" S.pp const T.pp t

    let to_string = Util.on_buffer pp

    let to_lit ~ord lit = match lit with
      | True -> Literal.mk_tauto
      | False -> Literal.mk_absurd
      | Eq (t, const) ->
        mk_eq ~ord t (T.mk_const const)
      | Neq (t, const) ->
        mk_neq ~ord t (T.mk_const const)
      | L_less (t, const) when S.is_int const ->
        (* t < c ----> t <= c - 1 *)
        mk_lesseq t (T.mk_const (S.Arith.Op.prec const))
      | L_less (t, const) ->
        mk_less t (T.mk_const const)
      | L_lesseq (t, const) ->
        mk_lesseq t (T.mk_const const)
      | R_less (const, t) when S.is_int const ->
        (* c < t ----> c+1 <= t  *)
        mk_lesseq (T.mk_const (S.Arith.Op.succ const)) t
      | R_less (const, t) ->
        mk_less (T.mk_const const) t
      | R_lesseq (const, t) ->
        mk_lesseq (T.mk_const const) t
  end

  (** {3 Comparison with 0} *)

  module Extracted = struct
    type t =
    | True
    | False
    | Eq of M.t  (* monome = 0 *)
    | Neq of M.t (* monome != 0 *)
    | Lt of M.t  (* monome < 0 *)
    | Leq of M.t (* monome <= 0 *)

    let pp buf lit = match lit with
    | True -> Buffer.add_string buf "true"
    | False -> Buffer.add_string buf "false"
    | Eq m -> Printf.bprintf buf "%a = 0" M.pp m
    | Neq m -> Printf.bprintf buf "%a ≠ 0" M.pp m
    | Lt m -> Printf.bprintf buf "%a < 0" M.pp m
    | Leq m -> Printf.bprintf buf "%a ≤ 0" M.pp m

    let to_string = Util.on_buffer pp

    let _extract lit =
      (* extract literal from (l=r | l!=r) *)
      let extract_eqn l r sign =
        let m1 = M.of_term l in
        let m2 = M.of_term r in
        let m = M.difference m1 m2 in
        (* remove denominator, it doesn't matter *)
        let m = M.normalize_eq_zero m in
        if M.is_constant m
        then if M.sign m = 0
          then if sign then True else False
          else if sign then False else True
        else if not (M.has_instances m) && sign
          then False
        else if sign
          then Eq m
          else Neq m
      (* extract lit from (l <= r | l < r) *)
      and extract_less ~strict l r =
        let m1 = M.of_term l in
        let m2 = M.of_term r in
        let m = M.difference m1 m2 in
        (* remove the denominator *)
        assert (S.Arith.sign m.M.divby > 0);
        let m = M.normalize_eq_zero m in
        if M.is_constant m then match M.sign m with
          | 0 -> if strict then False else True
          | n when n < 0 -> True
          | _ -> False
        else if strict && Type.eq (M.type_of m) Type.int
          then Leq M.(normalize_eq_zero (succ m))  (* m < 0 ---> m+1 <= 0 *)
        else if strict
          then Lt m
          else Leq m
      in
      let extract_le a b = extract_less ~strict:false a b in
      let extract_lt a b = extract_less ~strict:true a b in
      let ans = match lit with
      | Literal.True -> True
      | Literal.False -> False
      | Literal.Equation (l, r, sign, _) ->
        if T.is_arith l || T.is_arith r
          then extract_eqn l r sign
          else raise (Monome.NotLinear "lit.extract")
      | Literal.Prop ({T.term=T.Node (S.Const ("$less",_), _, [a; b])}, true) ->
        extract_lt a b
      | Literal.Prop ({T.term=T.Node (S.Const ("$less",_), _, [a; b])}, false) ->
        extract_le b a
      | Literal.Prop ({T.term=T.Node (S.Const ("$lesseq",_), _, [a; b])}, true) ->
        extract_le a b
      | Literal.Prop ({T.term=T.Node (S.Const ("$lesseq",_), _, [a; b])}, false) ->
        extract_lt b a
      | Literal.Prop ({T.term=T.Node (S.Const ("$greater",_), _, [a; b])}, true) ->
        extract_lt b a
      | Literal.Prop ({T.term=T.Node (S.Const ("$greater",_), _, [a; b])}, false) ->
        extract_le a b
      | Literal.Prop ({T.term=T.Node (S.Const ("$greatereq",_), _, [a; b])}, true) ->
        extract_le b a
      | Literal.Prop ({T.term=T.Node (S.Const ("$greatereq",_), _, [a; b])}, false) ->
        extract_lt a b
      | Literal.Prop _ -> raise (Monome.NotLinear "lit.extract")
      in
      Util.debug 5 "arith extraction of %a gives %a" Literal.pp lit pp ans;
      Util.exit_prof prof_arith_extract;
      ans

    module LitCache = Cache.Replacing(struct
      type t = Literal.t
      let equal = Literal.eq
      let hash = Literal.hash
    end)

    (* cache for literal extraction (because it will be called often
        on the same literals when distinct inference/simplification
        rules are run on a given clause *)
    let __cache = LitCache.create 512

    let extract lit =
      Util.enter_prof prof_arith_extract;
      let ans = LitCache.with_cache __cache _extract lit in
      Util.debug 5 "arith extraction of %a gives %a" Literal.pp lit pp ans;
      Util.exit_prof prof_arith_extract;
      ans

    let extract_opt lit =
      try Some (extract lit)
      with Monome.NotLinear _ -> None

    let get_monome = function
    | Eq m
    | Neq m
    | Lt m
    | Leq m -> m
    | True
    | False -> raise (Invalid_argument "arith.lit.extracted.get_monome")

    let to_lit ~ord lit =
      let mk_zero m =
        let ty = M.type_of m in
        T.mk_const (S.Arith.zero_of_ty ty)
      in
      match lit with
      | True -> Literal.mk_tauto
      | False -> Literal.mk_absurd
      | Eq m -> mk_eq ~ord (M.to_term m) (mk_zero m)
      | Neq m -> mk_neq ~ord (M.to_term m) (mk_zero m)
      | Lt m -> mk_less (M.to_term m) (mk_zero m)
      | Leq m -> mk_lesseq (M.to_term m) (mk_zero m)

    (* unify non-arith subterms pairwise *)
    let factor lit = match lit with
    | True
    | False -> []
    | _ ->
      let m = get_monome lit in
      (* all terms occurring immediately under the linear expression *)
      let l = M.terms m in
      let l = Util.list_diagonal l in
      Util.list_fmap
        (fun (t1, t2) ->
          try Some (FOUnif.unification t1 0 t2 0)
          with FOUnif.Fail -> None)
        l

    let eliminate ?fresh_var lit = match lit with
    | True
    | False -> []
    | Eq m -> M.Solve.neq_zero ?fresh_var m
    | Neq m -> M.Solve.eq_zero ?fresh_var m
    | Lt m -> M.Solve.leq_zero ?fresh_var (M.uminus m)
    | Leq m -> M.Solve.lt_zero ?fresh_var (M.uminus m)
  end

  (** {3 Literal with isolated term} *)

  module Pivoted = struct
    type t =
    | Eq of FOTerm.t * M.t
    | Neq of FOTerm.t * M.t
    | L_less of FOTerm.t * M.t   (* term < monome *)
    | L_lesseq of FOTerm.t * M.t
    | R_less of M.t * FOTerm.t
    | R_lesseq of M.t * FOTerm.t

    let pp buf lit = match lit with
    | Eq (t, m) -> Printf.bprintf buf "%a = %a" T.pp t M.pp m
    | Neq (t, m) -> Printf.bprintf buf "%a ≠ %a" T.pp t M.pp m
    | L_less (t, m) -> Printf.bprintf buf "%a < %a" T.pp t M.pp m
    | L_lesseq (t, m) -> Printf.bprintf buf "%a ≤ %a" T.pp t M.pp m
    | R_less (m, t) -> Printf.bprintf buf "%a < %a" M.pp m T.pp t
    | R_lesseq (m, t) -> Printf.bprintf buf "%a ≤ %a" M.pp m T.pp t

    module E = Extracted

    let to_string lit = Util.on_buffer pp lit

    let get_term = function
    | Eq (t, _)
    | Neq (t, _)
    | L_less (t, _)
    | L_lesseq (t, _)
    | R_less (_, t)
    | R_lesseq (_, t) -> t

    let get_monome = function
    | Eq (_, m)
    | Neq (_, m)
    | L_less (_, m)
    | L_lesseq (_, m)
    | R_less (m, _)
    | R_lesseq (m, _) -> m

    let to_lit ~ord lit =
      match lit with
      | Eq (t, m) -> mk_eq ~ord t (M.to_term m)
      | Neq (t, m) -> mk_neq ~ord t (M.to_term m)
      | L_less (t, m) -> mk_less t (M.to_term m)
      | L_lesseq (t, m) -> mk_lesseq t (M.to_term m)
      | R_less (m, t) -> mk_less (M.to_term m) t
      | R_lesseq (m, t) -> mk_lesseq (M.to_term m) t

    module List = struct
      let get_terms l =
        let set = T.Tbl.create 5 in
        List.iter
          (fun lit -> T.Tbl.replace set (get_term lit) ())
          l;
        T.Tbl.to_list set
    end
  end

  module E = Extracted

  (** {3 Pivot operation} *)

  type pivot_result =
    | Single of Single.t
    | Multiple of Pivoted.t list
    | True
    | False

  let pivot e =
    match e with
    | E.True -> True
    | E.False -> False
    | _ when M.size (E.get_monome e) = 1 ->
      (* convert to {!Single.t} *)
      let m = E.get_monome e in
      let is_int = S.is_int m.M.constant in
      let const = m.M.constant in
      let c, t = match M.to_list m with
        | [c, t] -> c, t
        | _ -> assert false
      in
      (* manage sign. we have (c*t + const) R 0, we can multiply by -1
          if needed, but [swap] is here to remember swapping sides in
          case R is an inequality. *)
      let swap, c, const = if S.Arith.sign c < 0
        then true, _uminus c, _uminus const
        else false, c, const
      in
      (* divide [const] by [c] if possible *)
      let c, const = if S.Arith.Op.divides c const
        then S.Arith.one_of_ty (S.ty c), S.Arith.Op.quotient const c
        else c, const
      in
      let lit' = match e with
      | E.True -> Single.True
      | E.False -> Single.False
      | E.Eq _ when not (S.Arith.is_one c) ->
        Single.False  (* 3 * t = 7 ----> false *)
      | E.Eq _ ->
        Single.Eq (t, _uminus const)
      | E.Neq _ when not (S.Arith.is_one c) ->
        Single.True   (* 3 * t != 7 ----> true *)
      | E.Neq _ ->
        Single.Neq (t, _uminus const)
      | E.Lt _ when not (S.Arith.is_one c) ->
        assert is_int;
        if swap
          then
            (* 3 * t > 7 -----> t > 7/3 ---> t >= 3 *)
            Single.R_lesseq (S.Arith.Op.(succ (quotient_f (_uminus const) c)), t)
          else
             (* 3 * t < 7 --->  t < 7/3 ----> t <= 2 *)
             Single.L_lesseq (t, S.Arith.Op.quotient_f (_uminus const) c)
      | E.Lt _ ->
        if swap
          then Single.R_less (_uminus const, t)
          else Single.L_less (t, _uminus const)
      | E.Leq _ when not (S.Arith.is_one c)->
        assert is_int;
        if swap
          then
            (* 3 * t >= 7 ---> t >= 7/3 ----> t >= 3 *)
            Single.R_lesseq (S.Arith.Op.(succ (quotient_f (_uminus const) c)), t)
          else
            (* 3 * t <= 7 ---> t <= 7/3 ----> t <= 2 *)
            Single.L_lesseq (t, S.Arith.Op.quotient_f (_uminus const) c)
      | E.Leq _ ->
        if swap
          then Single.R_lesseq (_uminus const, t)
          else Single.L_lesseq (t, _uminus const)
      in
      Single lit'
    | E.Eq m ->
      let terms = M.to_list m in
      Multiple (List.map
        (fun (coeff, t) ->
          assert (not (S.Arith.is_zero coeff));
          let m = M.divby (M.remove m t) (S.Arith.Op.abs coeff) in
          (* -t+m = 0 ---> t=m, but t+m = 0 ----> t=-m *)
          let m = if S.Arith.sign coeff < 0 then m else M.uminus m in
          Pivoted.Eq (t, m))
        terms)
    | E.Neq m ->
      let terms = M.to_list m in
      Multiple (List.map
        (fun (coeff, t) ->
          assert (not (S.Arith.is_zero coeff));
          let m = M.divby (M.remove m t) (S.Arith.Op.abs coeff) in
          (* -t+m != 0 ---> t=m, but t+m != 0 ----> t!=-m *)
          let m = if S.Arith.sign coeff < 0 then m else M.uminus m in
          Pivoted.Neq (t, m))
        terms)
    | E.Lt m ->
      let terms = M.to_list m in
      Multiple (List.map
        (fun (coeff, t) ->
          assert (not (S.Arith.is_zero coeff));
          (* do we have to change the sign of comparison? *)
          let swap = S.Arith.sign coeff < 0 in
          let m = M.divby (M.remove m t) (S.Arith.Op.abs coeff) in
          if swap
            then Pivoted.R_less (m, t)  (* -t+m < 0 ---> m < t *)
            else Pivoted.L_less (t, M.uminus m))  (* t+m < 0 ---> t < -m *)
        terms)
    | E.Leq m ->
      let terms = M.to_list m in
      Multiple (List.map
        (fun (coeff, t) ->
          assert (not (S.Arith.is_zero coeff));
          (* do we have to change the sign of comparison? *)
          let swap = S.Arith.sign coeff < 0 in
          let m = M.divby (M.remove m t) (S.Arith.Op.abs coeff) in
          if swap
            then Pivoted.R_lesseq (m, t)  (* -t+m <= 0 ---> m <= t *)
            else Pivoted.L_lesseq (t, M.uminus m))  (* t+m <= 0 ---> t <= -m *)
        terms)

  (** {3 High level operations} *)

  let is_trivial lit =
    match E.extract_opt lit with
    | Some E.True -> true
    | _ -> false

  let has_instances lit =
    match E.extract_opt lit with
    | Some E.False -> false
    | _ -> true

  (* be sure that the literal is "total", ie, if it's an equation, that
    replacing one side by the other is always safe.
    In particular:   a = b/3  is {b NOT} total for integers.
  *)
  let make_total ~ord lit =
    (* scale equation t = m so that m is a total expression *)
    let _scale_eqn t m lit =
      if not (M.total_expression m)
        then
          let t = T.mk_product (T.mk_const m.M.divby) t in
          let t' = M.to_term (M.product m m.M.divby) in
          mk_eq ~ord t t'
        else
          lit
    in
    match lit with
      | Literal.Equation (l, r, true, _) when not (T.is_arith l) ->
        begin try
          let m = M.of_term r in
          _scale_eqn l m lit
        with M.NotLinear _ -> lit
        end
      | Literal.Equation (l, r, true, _) when not (T.is_arith r) ->
        begin try
          let m = M.of_term l in
          _scale_eqn r m lit
        with M.NotLinear _ -> lit
        end
      | _ -> lit

  let simplify ~ord lit =
    try
      let elit = E.extract lit in
      match pivot elit with
      | True -> Literal.mk_tauto
      | False -> Literal.mk_absurd
      | Single s ->
        Util.debug 5 "arith.simplify %a into %a" Literal.pp lit Single.pp s;
        Single.to_lit ~ord s
      | Multiple _ ->
        (* do not chose a specific pivot *)
        lit
    with Monome.NotLinear _ ->
      Literal.fmap ~ord T.simplify lit

  (* find instances of variables that eliminate the literal *)
  let eliminate ?(elim_var=(fun v -> true)) ?fresh_var lit =
    (* find some solutions *)
    let solutions =
      try
        let elit = E.extract lit in
        E.eliminate ?fresh_var elit
      with Monome.NotLinear _ -> []
    in
    let unif_arith ~subst t1 sc_t m sc_m =
      FOUnif.unification ~subst t1 sc_t (M.to_term m) sc_m
    in
    Util.list_fmap
      (fun sol ->
        try
          (* make a substitution out of the solution *)
          let subst = List.fold_left
            (fun subst (t, m) ->
              (* check whether we can eliminate a variable *)
              if T.is_var t && not (elim_var t) then raise Exit;
              unif_arith ~subst t 0 m 0)
            Substs.FO.empty sol
          in
          Some subst
        with FOUnif.Fail | Exit -> None)
      solutions

  let heuristic_eliminate lit =
    match lit with
    | ( Literal.Equation ({T.term=T.Node(prod, _, [x1; x2])}, {T.term=T.Node(n,_,[])}, false, _)
      | Literal.Equation ({T.term=T.Node(n,_,[])}, {T.term=T.Node(prod, _,[x1; x2])}, false, _))
      when S.eq prod S.Arith.product && T.is_var x1 && T.eq x1 x2 && S.is_numeric n ->
      (* ahah, square root spotted! *)
      Util.debug 5 "heuristic_elim tries sqrt of %a" S.pp n;
      begin match n with
      | S.Int n ->
        if Big_int.sign_big_int n >= 0
          then
            let s = Big_int.sqrt_big_int n in
            if Big_int.eq_big_int (Big_int.square_big_int s) n
              then
                (* n is positive, and has an exact square root, try both
                    the positive and negative square roots*)
                [ Substs.FO.bind Substs.FO.empty x1 0 (T.mk_const (S.mk_bigint s)) 0
                ; Substs.FO.bind Substs.FO.empty x1 0
                  (T.mk_const (S.mk_bigint (Big_int.minus_big_int s))) 0 ]
              else []
          else []
      | S.Rat n -> []  (* TODO *)
      | S.Real n ->
        if n >= 0.
          then
            let s = sqrt n in
            [ Substs.FO.bind Substs.FO.empty x1 0 (T.mk_const (S.mk_real s)) 0
            ; Substs.FO.bind Substs.FO.empty x1 0 (T.mk_const (S.mk_real (~-. s))) 0
            ]
          else []
      | _ -> failwith "unknown numeric type!?"
      end
    | _ -> []
end

(** {2 Arrays of literals} *)

module Lits = struct
  let purify ~ord ~eligible lits =
    let new_lits = ref [] in
    let _add_lit lit = new_lits := lit :: !new_lits in
    let varidx = ref (T.max_var (Literals.vars lits) + 1) in
    (* purify a term (adding constraints to the list). [root] is true only
        if the term occurs in the outermost arith expression *)
    let rec purify_term ~root t = match t.T.term with
    | T.Var _
    | T.BoundVar _ -> t
    | T.Node (s, _, []) when S.is_numeric s -> t
    | T.Node (s, tyargs, l) when S.Arith.is_arith s ->
      if root
        then (* recurse, still in root arith expression *)
          T.mk_node ~tyargs s (List.map (purify_term ~root) l)
        else begin
          (* purify this term out! *)
          let ty = t.T.ty in
          let v = T.mk_var ~ty !varidx in
          incr varidx;
          (* purify the term and add a constraint *)
          let t' = purify_term ~root:true t in
          let lit = Literal.mk_neq ~ord v t' in
          _add_lit lit;
          (* return variable instead of literal *)
          v
        end
    | T.Node (s, tyargs, l) ->
      T.mk_node ~tyargs s (List.map (purify_term ~root:false) l)
    in
    (* purify each literal *)
    Array.iteri
      (fun i lit ->
        if eligible i lit
          then match lit with
          | Literal.Equation (l, r, sign, _) ->
            let l = purify_term ~root:true l in
            let r = purify_term r ~root:true in
            let lit = Literal.mk_lit ~ord l r sign in
            _add_lit lit
          | Literal.Prop (p, sign) ->
            let p = purify_term ~root:true p in
            let lit = Literal.mk_prop p sign in
            _add_lit lit
          | Literal.True -> _add_lit lit
          | Literal.False -> ()  (* useless *)
          else _add_lit lit (* keep *)
      )
      lits;
    Array.of_list (List.rev !new_lits)

  let pivot ~ord ~eligible lits =
    let results = ref [] in
    let add_res a = results := a :: !results in
    for i = 0 to Array.length lits - 1 do
      if eligible i lits.(i) then try
        (* try to pivot the i-th literal *)
        let elit = Lit.Extracted.extract lits.(i) in
        match Lit.pivot elit with
        | Lit.True
        | Lit.False
        | Lit.Single _ -> ()   (* already pivoted *)
        | Lit.Multiple pivots ->
          (* only keep maximal terms *)
          let terms = Lit.Pivoted.List.get_terms pivots in
          let terms = Multiset.create terms in
          let bv = Multiset.max (Ordering.compare ord) terms in
          let terms = BV.select bv (Multiset.to_array terms) in
          List.iter
            (fun lit' ->
              (* build a new literal from lit', if the term is maximal *)
              let t = Lit.Pivoted.get_term lit' in
              let m = Lit.Pivoted.get_monome lit' in
              let divby = m.Monome.divby in
              if List.exists (fun t' -> T.eq t t') terms then begin
                (* arith constraint, if required *)
                let constraint_ =
                  if Type.(eq int (S.ty divby)) && not (S.Arith.is_one divby) then
                    (* add a divisibility constraint:
                      let m = m' + c in m' mod i = -c *)
                    let c = S.Arith.Op.remainder_e (S.Arith.Op.uminus m.Monome.constant) divby in
                    let m' = Monome.(to_term (remove_const (remove_divby m))) in
                    let lit = Literal.mk_neq ~ord
                      (T.mk_remainder_e m' divby)
                      (T.mk_const c)
                    in
                    [lit]
                  else []
                in
                (* build new array of literals *)
                let lits = Util.array_except_idx lits i in
                let lits = Lit.Pivoted.to_lit ~ord lit' :: constraint_ @ lits in
                let lits = Array.of_list lits in
                add_res lits
              end)
            pivots
      with Monome.NotLinear _ -> ()
    done;
    !results

  let shielded ?(filter=(fun _ _ -> true)) lits v =
    if not (T.is_var v) then failwith "shielded: need a var";
    try
      for i = 0 to Array.length lits - 1 do
        if filter i lits.(i) &&
        match lits.(i) with
        | Literal.Prop (p, _) -> T.shielded v p
        | Literal.Equation (l, r, _, _) -> T.shielded v l || T.shielded v r
        | _ -> false
        then raise Exit
      done;
      false
    with Exit ->
      true

  let naked_vars ?filter lits =
    let vars = Literals.vars lits in
    List.filter (fun v -> not (shielded ?filter lits v)) vars

  let eliminate ~ord ~eligible lits =
    let results = ref [] in
    let lits' = Array.to_list lits in
    let add_res a = results := a :: !results in
    (* how to build fresh variables *)
    let fresh_var =
      let offset = ref (T.max_var (Literals.vars lits) + 1) in
      fun ty ->
        incr offset;
        T.mk_var ~ty !offset
    in
    (* instantiate with [subst]. Simplifications should then remove
        the literal; making the instantiation a step makes the proof
        more readable *)
    let eliminate_lit i subst =
      let renaming = Substs.FO.Renaming.create 5 in
      let lits' = Literal.apply_subst_list ~ord ~renaming subst lits' 0 in
      let lits' = Array.of_list lits' in
      add_res lits'
    in
    for i = 0 to Array.length lits - 1 do
      if eligible i lits.(i) then begin
        (* can eliminate only naked vars *)
        let elim_var =
          let vars = naked_vars ~filter:(fun i' _ -> i<>i') lits in
          fun v -> List.memq v vars
        in
        (* try heuristic substitutions *)
        let substs = Lit.heuristic_eliminate lits.(i) in
        (* try to eliminate literal as a linear expression *)
        let substs' = Lit.eliminate ~elim_var ~fresh_var lits.(i) in
        List.iter
          (fun subst -> eliminate_lit i subst)
          (substs @ substs');
      end
    done;
    !results
end
