val unify_scoped : Term.t Scoped.t -> Term.t Scoped.t -> Unif_subst.t option OSeq.t
val proj_hs : counter:int ref -> scope:Scoped.scope -> flex:Term.t -> Term.t -> Subst.FO.t CCList.t