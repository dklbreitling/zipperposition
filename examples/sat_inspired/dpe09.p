% /Users/blanchette/.isabelle/contrib/zipperposition-2.1-1/x86_64-darwin/zipperposition --input tptp --output tptp --timeout 30.000 --mode=ho-pragmatic --tptp-def-as-rewrite --rewrite-before-cnf=true --max-inferences=1 --ho-unif-max-depth=1 --ho-max-elims=0 --ho-max-app-projections=0 --ho-max-rigid-imitations=1 --ho-max-identifications=0 --boolean-reasoning=bool-hoist --bool-hoist-simpl=true --bool-select=LI --recognize-injectivity=true --ext-rules=ext-family --ext-rules-max-depth=1 --ho-choice-inst=true --ho-prim-enum=none --ho-elim-leibniz=0 --interpret-bool-funs=true --try-e="$E_HOME/eprover" --tmp-dir="$ISABELLE_TMP_PREFIX" --ho-unif-level=pragmatic-framework --select=bb+e-selection2 --post-cnf-lambda-lifting=true -q "4|prefer-sos|pnrefined(2,1,1,1,2,2,2)" -q "6|prefer-processed|conjecture-relative-struct(1.5,3.5,2,3)" -q "1|const|fifo" -q "4|prefer-ground|orient-lmax(2,1,2,1,1)" -q "4|defer-sos|conjecture-relative-struct(1,5,2,3)" --avatar=off --recognize-injectivity=true --ho-neg-ext=true --e-timeout=2 --ho-pattern-decider=true --ho-fixpoint-decider=true --e-max-derived=50 --ignore-orphans=true --e-auto=true --presaturate=true --e-call-point=0.1 /Users/blanchette/.isabelle/prob_zipperposition_1.p
% This file was generated by Isabelle (most likely Sledgehammer)
% 2022-06-15 17:15:31.039

% Could-be-implicit typings (1)
thf(ty_t_Option_Ooption, type,
    option : $tType > $tType).

% Explicit typings (6)
thf(sy_c_DPE_Oa, type,
    a : !>[A : $tType]: A).
thf(sy_c_DPE_Ob, type,
    b : !>[A : $tType]: A).
thf(sy_c_DPE_Oe, type,
    e : !>[A : $tType]: A).
thf(sy_c_DPE_Op, type,
    p : !>[A : $tType, B : $tType]: (A > B > $o)).
thf(sy_c_DPE_Oq, type,
    q : !>[A : $tType]: (A > A)).
thf(sy_c_DPE_Or, type,
    r : !>[A : $tType]: (A > A)).

% Relevant facts (5)
thf(fact_0_assms__9_I5_J, axiom,
    ((![I : $tType]: ((a @ (I)) = (b @ (I)))))). % assms_9(5)
thf(fact_1_assms__9_I4_J, axiom,
    ((![A : $tType, H : $tType]: (p @ ((option @ A)) @ (H) @ (a @ ((option @ A))) @ (b @ (H)))))). % assms_9(4)
thf(fact_2_assms__9_I3_J, axiom,
    ((![F : $tType, G : $tType]: (![X : F, Y : G]: ((p @ (F) @ (G) @ X @ Y) | ((r @ (G) @ Y) != (e @ (G)))))))). % assms_9(3)
thf(fact_3_assms__9_I2_J, axiom,
    ((![E : $tType, D : $tType]: (![X : D, Y : E]: ((p @ (D) @ (E) @ X @ Y) | ((q @ (D) @ X) != (e @ (D)))))))). % assms_9(2)
thf(fact_4_assms__9_I1_J, axiom,
    ((![B : $tType, C : $tType]: (![X : B, Y : C]: ((~ ((p @ (B) @ (C) @ X @ Y))) | (((q @ (B) @ X) = (e @ (B))) | ((r @ (C) @ Y) = (e @ (C))))))))). % assms_9(1)

% Conjectures (1)
thf(conj_0, conjecture,
    (($false))).
