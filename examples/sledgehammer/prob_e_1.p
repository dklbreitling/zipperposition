% TIMEFORMAT='%3R'; { time (exec 2>&1; /home/simon/.isabelle/contrib/e-1.8/x86_64-linux/eproof_ram --auto-schedule --tstp-in --tstp-out --silent --split-clauses=4 --split-reuse-defs --simul-paramod --forward-context-sr --destructive-er-aggressive --destructive-er --presat-simplify --prefer-initial-clauses -winvfreqrank -c1 -Ginvfreqconjmax -F1 --delete-bad-limit=150000000 -WSelectMaxLComplexAvoidPosPred -H'(4*FunWeight(SimulateSOS,20,20,1.5,1.5,1,aa_nat_bool:0,bit0:0,bit1:0,numeral_numeral_nat:0,one:0,p:0,pp:0,suc:0,plus_plus_num:8,bitM:10,one_one_nat:10,plus_plus_nat:10,numeral_numeral_int:11,one_one_int:11,plus_plus_int:11,zero_zero_nat:12,pred_numeral:15,zero_zero_int:18,neg_numeral_sub_int:20,neg_nu5851722552734809277nc_int:20,neg_numeral_dbl_int:22,divide_divide_nat:23,div_mod_nat:26,ord_less_num:27,neg_nu3811975205180677377ec_int:27,uminus_uminus_int:27,ord_less_eq_num:28,power_power_int:30,times_times_int:30,power_power_nat:30,times_times_nat:30,nat:31,aa_nat_fun_nat_bool:32,dvd_dvd_nat:32,minus_minus_nat:32,fFalse:32,fTrue:32,ord_less_eq_int:32,tt_bool:32,semiri1314217659103216013at_int:36,ord_less_eq_nat:37,divide_divide_int:38),3*ConjectureGeneralSymbolWeight(PreferNonGoals,200,100,200,50,50,1,100,1.5,1.5,1),1*Clauseweight(PreferProcessed,1,1,1),1*FIFOWeight(PreferProcessed))' --term-ordering=KBO6 --cpu-limit=5 --output-level=5 --pcl-shell-level=0 /home/simon/.isabelle/prob_e_1 ) ; }
% This file was generated by Isabelle (most likely Sledgehammer)
% 2016-05-18 17:50:15.576

% Explicit typings (3)
fof(tsy_c_aa_001t__Nat__Onat_001t__HOL__Obool, hypothesis,
    ((![B_1, B_2]: tt_bool(aa_nat_bool(B_1, B_2)) = aa_nat_bool(B_1, B_2)))).
fof(tsy_c_fFalse, axiom,
    (tt_bool(fFalse) = fFalse)).
fof(tsy_c_fTrue, axiom,
    (tt_bool(fTrue) = fTrue)).

% Relevant facts (148)
fof(fact_0_semiring__norm_I8_J, axiom,
    ((![M]: plus_plus_num(bit1(M), one) = bit0(plus_plus_num(M, one))))). % semiring_norm(8)
fof(fact_1_semiring__norm_I89_J, axiom,
    ((![M, N]: (~ bit1(M) = bit0(N))))). % semiring_norm(89)
fof(fact_2_Suc__numeral, axiom,
    ((![N]: suc(numeral_numeral_nat(N)) = numeral_numeral_nat(plus_plus_num(N, one))))). % Suc_numeral
fof(fact_3_eval__nat__numeral_I3_J, axiom,
    ((![N]: numeral_numeral_nat(bit1(N)) = suc(numeral_numeral_nat(bit0(N)))))). % eval_nat_numeral(3)
fof(fact_4_semiring__norm_I88_J, axiom,
    ((![M, N]: (~ bit0(M) = bit1(N))))). % semiring_norm(88)
fof(fact_5_semiring__norm_I5_J, axiom,
    ((![M]: plus_plus_num(bit0(M), one) = bit1(M)))). % semiring_norm(5)
fof(fact_6_semiring__norm_I86_J, axiom,
    ((![M]: (~ bit1(M) = one)))). % semiring_norm(86)
fof(fact_7_semiring__norm_I84_J, axiom,
    ((![N]: (~ one = bit1(N))))). % semiring_norm(84)
fof(fact_8_semiring__norm_I28_J, axiom,
    ((![N]: bitM(bit1(N)) = bit1(bit0(N))))). % semiring_norm(28)
fof(fact_9_Suc__eq__plus1__left, axiom,
    ((![N]: suc(N) = plus_plus_nat(one_one_nat, N)))). % Suc_eq_plus1_left
fof(fact_10_semiring__norm_I85_J, axiom,
    ((![M]: (~ bit0(M) = one)))). % semiring_norm(85)
fof(fact_11_one__plus__numeral, axiom,
    ((![N]: plus_plus_nat(one_one_nat, numeral_numeral_nat(N)) = numeral_numeral_nat(plus_plus_num(one, N))))). % one_plus_numeral
fof(fact_12_one__plus__numeral, axiom,
    ((![N]: plus_plus_int(one_one_int, numeral_numeral_int(N)) = numeral_numeral_int(plus_plus_num(one, N))))). % one_plus_numeral
fof(fact_13_semiring__norm_I83_J, axiom,
    ((![N]: (~ one = bit0(N))))). % semiring_norm(83)
fof(fact_14_semiring__norm_I3_J, axiom,
    ((![N]: plus_plus_num(one, bit0(N)) = bit1(N)))). % semiring_norm(3)
fof(fact_15_One__nat__def, axiom,
    (one_one_nat = suc(zero_zero_nat))). % One_nat_def
fof(fact_16_num_Oexhaust, axiom,
    ((![Y]: ((~ Y = one) => ((![X2]: (~ Y = bit0(X2))) => (~ (![X3]: (~ Y = bit1(X3))))))))). % num.exhaust
fof(fact_17_Suc__eq__plus1, axiom,
    ((![N]: suc(N) = plus_plus_nat(N, one_one_nat)))). % Suc_eq_plus1
fof(fact_18_numeral__2__eq__2, axiom,
    (numeral_numeral_nat(bit0(one)) = suc(suc(zero_zero_nat)))). % numeral_2_eq_2
fof(fact_19_numeral__plus__one, axiom,
    ((![N]: plus_plus_nat(numeral_numeral_nat(N), one_one_nat) = numeral_numeral_nat(plus_plus_num(N, one))))). % numeral_plus_one
fof(fact_20_numeral__plus__one, axiom,
    ((![N]: plus_plus_int(numeral_numeral_int(N), one_one_int) = numeral_numeral_int(plus_plus_num(N, one))))). % numeral_plus_one
fof(fact_21_Suc__1, axiom,
    (suc(one_one_nat) = numeral_numeral_nat(bit0(one)))). % Suc_1
fof(fact_22_num_Oinject_I2_J, axiom,
    ((![X32, Y3]: (bit1(X32) = bit1(Y3) <=> X32 = Y3)))). % num.inject(2)
fof(fact_23_add__Suc__right, axiom,
    ((![M, N]: plus_plus_nat(M, suc(N)) = suc(plus_plus_nat(M, N))))). % add_Suc_right
fof(fact_24_BitM__plus__one, axiom,
    ((![N]: plus_plus_num(bitM(N), one) = bit0(N)))). % BitM_plus_one
fof(fact_25_eval__nat__numeral_I2_J, axiom,
    ((![N]: numeral_numeral_nat(bit0(N)) = suc(numeral_numeral_nat(bitM(N)))))). % eval_nat_numeral(2)
fof(fact_26_semiring__norm_I90_J, axiom,
    ((![M, N]: (bit1(M) = bit1(N) <=> M = N)))). % semiring_norm(90)
fof(fact_27_num_Oinject_I1_J, axiom,
    ((![X22, Y2]: (bit0(X22) = bit0(Y2) <=> X22 = Y2)))). % num.inject(1)
fof(fact_28_pred__numeral__simps_I3_J, axiom,
    ((![K]: pred_numeral(bit1(K)) = numeral_numeral_nat(bit0(K))))). % pred_numeral_simps(3)
fof(fact_29_semiring__norm_I4_J, axiom,
    ((![N]: plus_plus_num(one, bit1(N)) = bit0(plus_plus_num(N, one))))). % semiring_norm(4)
fof(fact_30_Suc3__eq__add__3, axiom,
    ((![N]: suc(suc(suc(N))) = plus_plus_nat(numeral_numeral_nat(bit1(one)), N)))). % Suc3_eq_add_3
fof(fact_31_semiring__norm_I87_J, axiom,
    ((![M, N]: (bit0(M) = bit0(N) <=> M = N)))). % semiring_norm(87)
fof(fact_32_numeral__eq__iff, axiom,
    ((![M, N]: (numeral_numeral_nat(M) = numeral_numeral_nat(N) <=> M = N)))). % numeral_eq_iff
fof(fact_33_numeral__eq__iff, axiom,
    ((![M, N]: (numeral_numeral_int(M) = numeral_numeral_int(N) <=> M = N)))). % numeral_eq_iff
fof(fact_34_semiring__norm_I2_J, axiom,
    (plus_plus_num(one, one) = bit0(one))). % semiring_norm(2)
fof(fact_35_numeral__One, axiom,
    (numeral_numeral_nat(one) = one_one_nat)). % numeral_One
fof(fact_36_numeral__One, axiom,
    (numeral_numeral_int(one) = one_one_int)). % numeral_One
fof(fact_37_pred__numeral__simps_I1_J, axiom,
    (pred_numeral(one) = zero_zero_nat)). % pred_numeral_simps(1)
fof(fact_38_pred__numeral__simps_I2_J, axiom,
    ((![K]: pred_numeral(bit0(K)) = numeral_numeral_nat(bitM(K))))). % pred_numeral_simps(2)
fof(fact_39_num_Odistinct_I1_J, axiom,
    ((![X22]: (~ one = bit0(X22))))). % num.distinct(1)
fof(fact_40_nat_Oinject, axiom,
    ((![X22, Y2]: (suc(X22) = suc(Y2) <=> X22 = Y2)))). % nat.inject
fof(fact_41_add__2__eq__Suc_H, axiom,
    ((![N]: plus_plus_nat(N, numeral_numeral_nat(bit0(one))) = suc(suc(N))))). % add_2_eq_Suc'
fof(fact_42_Suc__eq__numeral, axiom,
    ((![N, K]: (suc(N) = numeral_numeral_nat(K) <=> N = pred_numeral(K))))). % Suc_eq_numeral
fof(fact_43_numeral__Bit0, axiom,
    ((![N]: numeral_numeral_nat(bit0(N)) = plus_plus_nat(numeral_numeral_nat(N), numeral_numeral_nat(N))))). % numeral_Bit0
fof(fact_44_numeral__Bit0, axiom,
    ((![N]: numeral_numeral_int(bit0(N)) = plus_plus_int(numeral_numeral_int(N), numeral_numeral_int(N))))). % numeral_Bit0
fof(fact_45_add_Oright__neutral, axiom,
    ((![A]: plus_plus_nat(A, zero_zero_nat) = A))). % add.right_neutral
fof(fact_46_add_Oright__neutral, axiom,
    ((![A]: plus_plus_int(A, zero_zero_int) = A))). % add.right_neutral
fof(fact_47_num_Odistinct_I3_J, axiom,
    ((![X32]: (~ one = bit1(X32))))). % num.distinct(3)
fof(fact_48_numeral__Bit1, axiom,
    ((![N]: numeral_numeral_nat(bit1(N)) = plus_plus_nat(plus_plus_nat(numeral_numeral_nat(N), numeral_numeral_nat(N)), one_one_nat)))). % numeral_Bit1
fof(fact_49_numeral__Bit1, axiom,
    ((![N]: numeral_numeral_int(bit1(N)) = plus_plus_int(plus_plus_int(numeral_numeral_int(N), numeral_numeral_int(N)), one_one_int)))). % numeral_Bit1
fof(fact_50_add__2__eq__Suc, axiom,
    ((![N]: plus_plus_nat(numeral_numeral_nat(bit0(one)), N) = suc(suc(N))))). % add_2_eq_Suc
fof(fact_51_num_Odistinct_I5_J, axiom,
    ((![X22, X32]: (~ bit0(X22) = bit1(X32))))). % num.distinct(5)
fof(fact_52_sub__num__simps_I5_J, axiom,
    ((![K]: neg_numeral_sub_int(bit1(K), one) = numeral_numeral_int(bit0(K))))). % sub_num_simps(5)
fof(fact_53_numeral__1__eq__Suc__0, axiom,
    (numeral_numeral_nat(one) = suc(zero_zero_nat))). % numeral_1_eq_Suc_0
fof(fact_54_dbl__inc__simps_I5_J, axiom,
    ((![K]: neg_nu5851722552734809277nc_int(numeral_numeral_int(K)) = numeral_numeral_int(bit1(K))))). % dbl_inc_simps(5)
fof(fact_55_old_Onat_Oinject, axiom,
    ((![Nat, Nat2]: (suc(Nat) = suc(Nat2) <=> Nat = Nat2)))). % old.nat.inject
fof(fact_56_add_Ocommute, axiom,
    ((![A, B]: plus_plus_int(A, B) = plus_plus_int(B, A)))). % add.commute
fof(fact_57_add_Ocommute, axiom,
    ((![A, B]: plus_plus_nat(A, B) = plus_plus_nat(B, A)))). % add.commute
fof(fact_58_add_Oleft__commute, axiom,
    ((![B, A, C]: plus_plus_int(B, plus_plus_int(A, C)) = plus_plus_int(A, plus_plus_int(B, C))))). % add.left_commute
fof(fact_59_add_Oleft__commute, axiom,
    ((![B, A, C]: plus_plus_nat(B, plus_plus_nat(A, C)) = plus_plus_nat(A, plus_plus_nat(B, C))))). % add.left_commute
fof(fact_60_add__left__cancel, axiom,
    ((![A, B, C]: (plus_plus_int(A, B) = plus_plus_int(A, C) <=> B = C)))). % add_left_cancel
fof(fact_61_add__left__cancel, axiom,
    ((![A, B, C]: (plus_plus_nat(A, B) = plus_plus_nat(A, C) <=> B = C)))). % add_left_cancel
fof(fact_62_dbl__simps_I5_J, axiom,
    ((![K]: neg_numeral_dbl_int(numeral_numeral_int(K)) = numeral_numeral_int(bit0(K))))). % dbl_simps(5)
fof(fact_63_dbl__inc__simps_I3_J, axiom,
    (neg_nu5851722552734809277nc_int(one_one_int) = numeral_numeral_int(bit1(one)))). % dbl_inc_simps(3)
fof(fact_64_eq__numeral__Suc, axiom,
    ((![K, N]: (numeral_numeral_nat(K) = suc(N) <=> pred_numeral(K) = N)))). % eq_numeral_Suc
fof(fact_65_div__Suc__eq__div__add3, axiom,
    ((![M, N]: divide_divide_nat(M, suc(suc(suc(N)))) = divide_divide_nat(M, plus_plus_nat(numeral_numeral_nat(bit1(one)), N))))). % div_Suc_eq_div_add3
fof(fact_66_Suc__div__eq__add3__div, axiom,
    ((![M, N]: divide_divide_nat(suc(suc(suc(M))), N) = divide_divide_nat(plus_plus_nat(numeral_numeral_nat(bit1(one)), M), N)))). % Suc_div_eq_add3_div
fof(fact_67_numeral__plus__numeral, axiom,
    ((![M, N]: plus_plus_nat(numeral_numeral_nat(M), numeral_numeral_nat(N)) = numeral_numeral_nat(plus_plus_num(M, N))))). % numeral_plus_numeral
fof(fact_68_numeral__plus__numeral, axiom,
    ((![M, N]: plus_plus_int(numeral_numeral_int(M), numeral_numeral_int(N)) = numeral_numeral_int(plus_plus_num(M, N))))). % numeral_plus_numeral
fof(fact_69_Suc__div__eq__add3__div__numeral, axiom,
    ((![M, V]: divide_divide_nat(suc(suc(suc(M))), numeral_numeral_nat(V)) = divide_divide_nat(plus_plus_nat(numeral_numeral_nat(bit1(one)), M), numeral_numeral_nat(V))))). % Suc_div_eq_add3_div_numeral
fof(fact_70_one__add__one, axiom,
    (plus_plus_nat(one_one_nat, one_one_nat) = numeral_numeral_nat(bit0(one)))). % one_add_one
fof(fact_71_one__add__one, axiom,
    (plus_plus_int(one_one_int, one_one_int) = numeral_numeral_int(bit0(one)))). % one_add_one
fof(fact_72_add__numeral__left, axiom,
    ((![V, W, Z]: plus_plus_nat(numeral_numeral_nat(V), plus_plus_nat(numeral_numeral_nat(W), Z)) = plus_plus_nat(numeral_numeral_nat(plus_plus_num(V, W)), Z)))). % add_numeral_left
fof(fact_73_add__numeral__left, axiom,
    ((![V, W, Z]: plus_plus_int(numeral_numeral_int(V), plus_plus_int(numeral_numeral_int(W), Z)) = plus_plus_int(numeral_numeral_int(plus_plus_num(V, W)), Z)))). % add_numeral_left
fof(fact_74_add__is__0, axiom,
    ((![M, N]: (plus_plus_nat(M, N) = zero_zero_nat <=> (M = zero_zero_nat & N = zero_zero_nat))))). % add_is_0
fof(fact_75_Nat_Oadd__0__right, axiom,
    ((![M]: plus_plus_nat(M, zero_zero_nat) = M))). % Nat.add_0_right
fof(fact_76_numeral__eq__one__iff, axiom,
    ((![N]: (numeral_numeral_nat(N) = one_one_nat <=> N = one)))). % numeral_eq_one_iff
fof(fact_77_numeral__eq__one__iff, axiom,
    ((![N]: (numeral_numeral_int(N) = one_one_int <=> N = one)))). % numeral_eq_one_iff
fof(fact_78_one__eq__numeral__iff, axiom,
    ((![N]: (one_one_nat = numeral_numeral_nat(N) <=> one = N)))). % one_eq_numeral_iff
fof(fact_79_one__eq__numeral__iff, axiom,
    ((![N]: (one_one_int = numeral_numeral_int(N) <=> one = N)))). % one_eq_numeral_iff
fof(fact_80_add_Oleft__neutral, axiom,
    ((![A]: plus_plus_nat(zero_zero_nat, A) = A))). % add.left_neutral
fof(fact_81_add_Oleft__neutral, axiom,
    ((![A]: plus_plus_int(zero_zero_int, A) = A))). % add.left_neutral
fof(fact_82_Suc__mod__eq__add3__mod, axiom,
    ((![M, N]: div_mod_nat(suc(suc(suc(M))), N) = div_mod_nat(plus_plus_nat(numeral_numeral_nat(bit1(one)), M), N)))). % Suc_mod_eq_add3_mod
fof(fact_83_add__Suc, axiom,
    ((![M, N]: plus_plus_nat(suc(M), N) = suc(plus_plus_nat(M, N))))). % add_Suc
fof(fact_84_semiring__norm_I80_J, axiom,
    ((![M, N]: (ord_less_num(bit1(M), bit1(N)) <=> ord_less_num(M, N))))). % semiring_norm(80)
fof(fact_85_dbl__dec__simps_I4_J, axiom,
    (neg_nu3811975205180677377ec_int(uminus_uminus_int(one_one_int)) = uminus_uminus_int(numeral_numeral_int(bit1(one))))). % dbl_dec_simps(4)
fof(fact_86_dbl__def, axiom,
    ((![X]: neg_numeral_dbl_int(X) = plus_plus_int(X, X)))). % dbl_def
fof(fact_87_is__num__normalize_I1_J, axiom,
    ((![A, B, C]: plus_plus_int(plus_plus_int(A, B), C) = plus_plus_int(A, plus_plus_int(B, C))))). % is_num_normalize(1)
fof(fact_88_dbl__inc__def, axiom,
    ((![X]: neg_nu5851722552734809277nc_int(X) = plus_plus_int(plus_plus_int(X, X), one_one_int)))). % dbl_inc_def
fof(fact_89_sub__num__simps_I1_J, axiom,
    (neg_numeral_sub_int(one, one) = zero_zero_int)). % sub_num_simps(1)
fof(fact_90_semiring__norm_I79_J, axiom,
    ((![M, N]: (ord_less_num(bit0(M), bit1(N)) <=> ord_less_eq_num(M, N))))). % semiring_norm(79)
fof(fact_91_dbl__simps_I3_J, axiom,
    (neg_numeral_dbl_int(one_one_int) = numeral_numeral_int(bit0(one)))). % dbl_simps(3)
fof(fact_92_nat__induct, axiom,
    ((![P, N]: (pp(aa_nat_bool(P, zero_zero_nat)) => ((![N2]: (pp(aa_nat_bool(P, N2)) => pp(aa_nat_bool(P, suc(N2))))) => pp(aa_nat_bool(P, N))))))). % nat_induct
fof(fact_93_mod__Suc__eq__mod__add3, axiom,
    ((![M, N]: div_mod_nat(M, suc(suc(suc(N)))) = div_mod_nat(M, plus_plus_nat(numeral_numeral_nat(bit1(one)), N))))). % mod_Suc_eq_mod_add3
fof(fact_94_sub__num__simps_I9_J, axiom,
    ((![K, L]: neg_numeral_sub_int(bit1(K), bit1(L)) = neg_numeral_dbl_int(neg_numeral_sub_int(K, L))))). % sub_num_simps(9)
fof(fact_95_sub__num__simps_I6_J, axiom,
    ((![K, L]: neg_numeral_sub_int(bit0(K), bit0(L)) = neg_numeral_dbl_int(neg_numeral_sub_int(K, L))))). % sub_num_simps(6)
fof(fact_96_dbl__simps_I2_J, axiom,
    (neg_numeral_dbl_int(zero_zero_int) = zero_zero_int)). % dbl_simps(2)
fof(fact_97_sub__num__simps_I8_J, axiom,
    ((![K, L]: neg_numeral_sub_int(bit1(K), bit0(L)) = neg_nu5851722552734809277nc_int(neg_numeral_sub_int(K, L))))). % sub_num_simps(8)
fof(fact_98_Suc__mod__eq__add3__mod__numeral, axiom,
    ((![M, V]: div_mod_nat(suc(suc(suc(M))), numeral_numeral_nat(V)) = div_mod_nat(plus_plus_nat(numeral_numeral_nat(bit1(one)), M), numeral_numeral_nat(V))))). % Suc_mod_eq_add3_mod_numeral
fof(fact_99_sub__num__simps_I4_J, axiom,
    ((![K]: neg_numeral_sub_int(bit0(K), one) = numeral_numeral_int(bitM(K))))). % sub_num_simps(4)
fof(fact_100_power__Suc, axiom,
    ((![A, N]: power_power_int(A, suc(N)) = times_times_int(A, power_power_int(A, N))))). % power_Suc
fof(fact_101_power__Suc, axiom,
    ((![A, N]: power_power_nat(A, suc(N)) = times_times_nat(A, power_power_nat(A, N))))). % power_Suc
fof(fact_102_nat__numeral, axiom,
    ((![K]: nat(numeral_numeral_int(K)) = numeral_numeral_nat(K)))). % nat_numeral
fof(fact_103_mult_Oleft__neutral, axiom,
    ((![A]: times_times_nat(one_one_nat, A) = A))). % mult.left_neutral
fof(fact_104_mult_Oleft__neutral, axiom,
    ((![A]: times_times_int(one_one_int, A) = A))). % mult.left_neutral
fof(fact_105_mult_Oright__neutral, axiom,
    ((![A]: times_times_nat(A, one_one_nat) = A))). % mult.right_neutral
fof(fact_106_mult_Oright__neutral, axiom,
    ((![A]: times_times_int(A, one_one_int) = A))). % mult.right_neutral
fof(fact_107_nat__1__add__1, axiom,
    (plus_plus_nat(one_one_nat, one_one_nat) = numeral_numeral_nat(bit0(one)))). % nat_1_add_1
fof(fact_108_dbl__inc__simps_I2_J, axiom,
    (neg_nu5851722552734809277nc_int(zero_zero_int) = one_one_int)). % dbl_inc_simps(2)
fof(fact_109_div2__Suc__Suc, axiom,
    ((![M]: divide_divide_nat(suc(suc(M)), numeral_numeral_nat(bit0(one))) = suc(divide_divide_nat(M, numeral_numeral_nat(bit0(one))))))). % div2_Suc_Suc
fof(fact_110_odd__mod__4__div__2, axiom,
    ((![N]: (div_mod_nat(N, numeral_numeral_nat(bit0(bit0(one)))) = numeral_numeral_nat(bit1(one)) => (~ pp(aa_nat_bool(aa_nat_fun_nat_bool(dvd_dvd_nat, numeral_numeral_nat(bit0(one))), divide_divide_nat(minus_minus_nat(N, one_one_nat), numeral_numeral_nat(bit0(one)))))))))). % odd_mod_4_div_2
fof(fact_111_Nat__Transfer_Otransfer__nat__int__function__closures_I8_J, axiom,
    (ord_less_eq_int(zero_zero_int, numeral_numeral_int(bit1(one))))). % Nat_Transfer.transfer_nat_int_function_closures(8)
fof(fact_112_power__0, axiom,
    ((![A]: power_power_nat(A, zero_zero_nat) = one_one_nat))). % power_0
fof(fact_113_power__0, axiom,
    ((![A]: power_power_int(A, zero_zero_nat) = one_one_int))). % power_0
fof(fact_114_nat__add__right__cancel, axiom,
    ((![M, K, N]: (plus_plus_nat(M, K) = plus_plus_nat(N, K) <=> M = N)))). % nat_add_right_cancel
fof(fact_115_transfer__nat__int__numerals_I4_J, axiom,
    (numeral_numeral_nat(bit1(one)) = nat(numeral_numeral_int(bit1(one))))). % transfer_nat_int_numerals(4)
fof(fact_116_nat__add__left__cancel, axiom,
    ((![K, M, N]: (plus_plus_nat(K, M) = plus_plus_nat(K, N) <=> M = N)))). % nat_add_left_cancel
fof(fact_117_zero__neq__numeral, axiom,
    ((![N]: (~ zero_zero_nat = numeral_numeral_nat(N))))). % zero_neq_numeral
fof(fact_118_zero__neq__numeral, axiom,
    ((![N]: (~ zero_zero_int = numeral_numeral_int(N))))). % zero_neq_numeral
fof(fact_119_one__is__add, axiom,
    ((![M, N]: (suc(zero_zero_nat) = plus_plus_nat(M, N) <=> ((M = suc(zero_zero_nat) & N = zero_zero_nat) | (M = zero_zero_nat & N = suc(zero_zero_nat))))))). % one_is_add
fof(fact_120_nat__1, axiom,
    (nat(one_one_int) = suc(zero_zero_nat))). % nat_1
fof(fact_121_add__is__1, axiom,
    ((![M, N]: (plus_plus_nat(M, N) = suc(zero_zero_nat) <=> ((M = suc(zero_zero_nat) & N = zero_zero_nat) | (M = zero_zero_nat & N = suc(zero_zero_nat))))))). % add_is_1
fof(fact_122_plus__nat_Oadd__0, axiom,
    ((![N]: plus_plus_nat(zero_zero_nat, N) = N))). % plus_nat.add_0
fof(fact_123_Nat__Transfer_Otransfer__nat__int__function__closures_I7_J, axiom,
    (ord_less_eq_int(zero_zero_int, numeral_numeral_int(bit0(one))))). % Nat_Transfer.transfer_nat_int_function_closures(7)
fof(fact_124_add__eq__self__zero, axiom,
    ((![M, N]: (plus_plus_nat(M, N) = M => N = zero_zero_nat)))). % add_eq_self_zero
fof(fact_125_nat_Odistinct_I1_J, axiom,
    ((![X22]: (~ zero_zero_nat = suc(X22))))). % nat.distinct(1)
fof(fact_126_transfer__int__nat__numerals_I4_J, axiom,
    (numeral_numeral_int(bit1(one)) = semiri1314217659103216013at_int(numeral_numeral_nat(bit1(one))))). % transfer_int_nat_numerals(4)
fof(fact_127_old_Onat_Odistinct_I2_J, axiom,
    ((![Nat2]: (~ suc(Nat2) = zero_zero_nat)))). % old.nat.distinct(2)
fof(fact_128_sub__num__simps_I3_J, axiom,
    ((![L]: neg_numeral_sub_int(one, bit1(L)) = uminus_uminus_int(numeral_numeral_int(bit0(L)))))). % sub_num_simps(3)
fof(fact_129_even__Suc__Suc__iff, axiom,
    ((![N]: (pp(aa_nat_bool(aa_nat_fun_nat_bool(dvd_dvd_nat, numeral_numeral_nat(bit0(one))), suc(suc(N)))) <=> pp(aa_nat_bool(aa_nat_fun_nat_bool(dvd_dvd_nat, numeral_numeral_nat(bit0(one))), N)))))). % even_Suc_Suc_iff
fof(fact_130_old_Onat_Odistinct_I1_J, axiom,
    ((![Nat2]: (~ zero_zero_nat = suc(Nat2))))). % old.nat.distinct(1)
fof(fact_131_minus__minus, axiom,
    ((![A]: uminus_uminus_int(uminus_uminus_int(A)) = A))). % minus_minus
fof(fact_132_order__refl, axiom,
    ((![X]: pp(aa_nat_bool(aa_nat_fun_nat_bool(ord_less_eq_nat, X), X))))). % order_refl
fof(fact_133_order__refl, axiom,
    ((![X]: ord_less_eq_num(X, X)))). % order_refl
fof(fact_134_order__refl, axiom,
    ((![X]: ord_less_eq_int(X, X)))). % order_refl
fof(fact_135_nat_OdiscI, axiom,
    ((![Nat, X22]: (Nat = suc(X22) => (~ Nat = zero_zero_nat))))). % nat.discI
fof(fact_136_add__Suc__shift, axiom,
    ((![M, N]: plus_plus_nat(suc(M), N) = plus_plus_nat(M, suc(N))))). % add_Suc_shift
fof(fact_137_zdiv__numeral__Bit1, axiom,
    ((![V, W]: divide_divide_int(numeral_numeral_int(bit1(V)), numeral_numeral_int(bit0(W))) = divide_divide_int(numeral_numeral_int(V), numeral_numeral_int(W))))). % zdiv_numeral_Bit1
fof(fact_138_zero__induct, axiom,
    ((![P, K]: (pp(aa_nat_bool(P, K)) => ((![N2]: (pp(aa_nat_bool(P, suc(N2))) => pp(aa_nat_bool(P, N2)))) => pp(aa_nat_bool(P, zero_zero_nat))))))). % zero_induct
fof(fact_139_diff__induct, axiom,
    ((![P, M, N]: ((![X4]: pp(aa_nat_bool(aa_nat_fun_nat_bool(P, X4), zero_zero_nat))) => ((![Y4]: pp(aa_nat_bool(aa_nat_fun_nat_bool(P, zero_zero_nat), suc(Y4)))) => ((![X4, Y4]: (pp(aa_nat_bool(aa_nat_fun_nat_bool(P, X4), Y4)) => pp(aa_nat_bool(aa_nat_fun_nat_bool(P, suc(X4)), suc(Y4))))) => pp(aa_nat_bool(aa_nat_fun_nat_bool(P, M), N)))))))). % diff_induct
fof(fact_140_one__plus__numeral__commute, axiom,
    ((![X]: plus_plus_nat(one_one_nat, numeral_numeral_nat(X)) = plus_plus_nat(numeral_numeral_nat(X), one_one_nat)))). % one_plus_numeral_commute
fof(fact_141_one__plus__numeral__commute, axiom,
    ((![X]: plus_plus_int(one_one_int, numeral_numeral_int(X)) = plus_plus_int(numeral_numeral_int(X), one_one_int)))). % one_plus_numeral_commute
fof(fact_142_numerals_I1_J, axiom,
    (numeral_numeral_nat(one) = one_one_nat)). % numerals(1)
fof(fact_143_Suc__neq__Zero, axiom,
    ((![M]: (~ suc(M) = zero_zero_nat)))). % Suc_neq_Zero
fof(fact_144_power3__eq__cube, axiom,
    ((![A]: power_power_int(A, numeral_numeral_nat(bit1(one))) = times_times_int(times_times_int(A, A), A)))). % power3_eq_cube
fof(fact_145_power3__eq__cube, axiom,
    ((![A]: power_power_nat(A, numeral_numeral_nat(bit1(one))) = times_times_nat(times_times_nat(A, A), A)))). % power3_eq_cube
fof(fact_146_add__nonneg__nonneg, axiom,
    ((![A, B]: (pp(aa_nat_bool(aa_nat_fun_nat_bool(ord_less_eq_nat, zero_zero_nat), A)) => (pp(aa_nat_bool(aa_nat_fun_nat_bool(ord_less_eq_nat, zero_zero_nat), B)) => pp(aa_nat_bool(aa_nat_fun_nat_bool(ord_less_eq_nat, zero_zero_nat), plus_plus_nat(A, B)))))))). % add_nonneg_nonneg
fof(fact_147_add__nonneg__nonneg, axiom,
    ((![A, B]: (ord_less_eq_int(zero_zero_int, A) => (ord_less_eq_int(zero_zero_int, B) => ord_less_eq_int(zero_zero_int, plus_plus_int(A, B))))))). % add_nonneg_nonneg

% Helper facts (2)
fof(help_pp_2_1_U, axiom,
    (pp(fTrue))).
fof(help_pp_1_1_U, axiom,
    ((~ pp(fFalse)))).

% Conjectures (2)
fof(conj_0, conjecture,
    ((~ pp(aa_nat_bool(p, numeral_numeral_nat(bit0(bit1(bit1(bit1(one)))))))))).
fof(conj_1, conjecture,
    (pp(aa_nat_bool(p, suc(suc(suc(numeral_numeral_nat(bit1(bit1(bit0(bit1(one)))))))))))).
