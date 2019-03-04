(* This file is free software, part of Zipperposition. See file "license" for more details. *)

module T = Term
module US = Unif_subst

type subst = US.t

module S : sig

  val apply : subst -> T.t Scoped.t -> T.t

end

val set_huet_style : unit -> unit

val project_onesided : scope:Scoped.scope -> fresh_var_:int ref -> T.t -> subst OSeq.t

val imitate : scope:Scoped.scope -> fresh_var_:int ref -> T.t -> T.t -> (T.var * int) list -> subst OSeq.t

val identify : scope:Scoped.scope -> fresh_var_:int ref -> T.t -> T.t -> (T.var * int) list -> subst OSeq.t

val eliminate : scope:Scoped.scope -> fresh_var_:int ref -> T.t -> T.t -> (Type.t HVar.t * int) list -> subst OSeq.t

(** Find disagreeing subterms. 
    This function also returns a list of variables occurring above the
    disagreement pair, along with the index of the argument that the disagreement
    pair occurs in. *)
val find_disagreement : T.t -> T.t -> ((T.t * T.t) * (T.var * int) CCList.t) option

(* Unify terms of the same scope. Assumes that terms are in eta-long form. *)
val unify : scope:Scoped.scope -> fresh_var_:int ref -> T.t -> T.t -> subst option OSeq.t

(* Unify scoped terms and removes "None"s, resulting in a potentially non-terminating function. Assumes that terms are in eta-long form. *)
val unify_scoped_nonterminating : T.t Scoped.t -> T.t Scoped.t -> subst OSeq.t

(* Unify scoped terms. Assumes that terms are in eta-long form. *)
val unify_scoped : T.t Scoped.t -> T.t Scoped.t -> subst option OSeq.t