
open Logtk
module Q = QCheck

module M = Multiset.Make(struct
  type t = int
  let compare i j=Pervasives.compare i j
end)

(* for testing *)
let m_test = Alcotest.testable (M.pp Fmt.int) M.equal
let z_test = Alcotest.testable Z.pp_print Z.equal

let f x y =
  if x = y then Comparison.Nonstrict.Eq
  else if x < y then Lt
  else Gt

let test_max = "multiset.max", `Quick, fun()->
  let m = M.of_list [1;2;2;3;1] in
  Alcotest.(check m_test) "must be equal" (M.of_list [3]) (M.max f m)

let test_compare = "multiset.compare", `Quick, fun()->
  let m1 = M.of_list [1;1;2;3] in
  let m2 = M.of_list [1;2;2;3] in
  Alcotest.(check (module Comparison.Nonstrict)) "must be lt"
    Comparison.Nonstrict.Lt (M.compare_partial_nonstrict f m1 m2);
  Alcotest.(check bool) "ord" true (M.compare m1 m2 < 0);
  ()

let test_cardinal_size = "multiset.size", `Quick, fun()->
  let m = M.of_coeffs [1, Z.(~$ 2); 3, Z.(~$ 40)] in
  Alcotest.(check int) "size=2" 2 (M.size m);
  Alcotest.(check z_test) "cardinal=42" Z.(~$ 42) (M.cardinal m);
  ()

let _sign = function
  | 0 -> 0
  | n when n < 0 -> -1
  | _ -> 1

let gen1 =
  let pp1 = CCFormat.to_string (M.pp CCFormat.int) in
  let shrink_z z =
    try Z.to_int z |> Q.Shrink.int |> Q.Iter.map Z.of_int
    with _ -> Q.Iter.empty
  in
  let shrink2 = Q.Shrink.pair Q.Shrink.nil shrink_z in
  let shrink l =
    M.to_list l
    |> Q.Shrink.(list ~shrink:shrink2)
    |> Q.Iter.map M.of_coeffs
  in
  Q.(small_list small_int
     |> map M.of_list
     |> set_print pp1
     |> set_shrink shrink)

let compare_and_partial =
  (* "naive" comparison function (using the general ordering on multisets) *)
  let compare' m1 m2 =
    let f x y = Comparison.Nonstrict.of_total (CCInt.compare x y) in
    Comparison.Nonstrict.to_total (M.compare_partial_nonstrict f m1 m2)
  in
  let prop (m1,m2) =
    _sign (compare' m1 m2) = _sign (M.compare m1 m2)
  in
  QCheck.Test.make
    ~name:"multiset_compare_and_compare_partial" ~long_factor:3 ~count:1000
    (Q.pair gen1 gen1) prop

(* partial order for tests *)
let partial_ord (x:int) y =
  if x=y then Comparison.Eq
  else if (x/5=y/5 && x mod 5 <> y mod 5) then Comparison.Incomparable
  else CCInt.compare (x/5) (y/5) |> Comparison.of_total

let partial_ord_nonstrict x y = Comparison.to_nonstrict (partial_ord x y)

let compare_partial_sym =
  let prop (m1,m2) =
    let c1 = M.compare_partial_nonstrict partial_ord_nonstrict m1 m2 in
    let c2 =  Comparison.Nonstrict.opp (M.compare_partial_nonstrict partial_ord_nonstrict m2 m1) in
    if c1=c2 
    then true
    else Q.Test.fail_reportf "comparison: %a vs %a" Comparison.Nonstrict.pp c1 Comparison.Nonstrict.pp c2
  in
  QCheck.Test.make
    ~name:"multiset_compare_partial_sym" ~long_factor:3 ~count:13_000
    Q.(pair gen1 gen1) prop

let compare_partial_trans =
  let prop (m1,m2,m3) =
    let c1 = M.compare_partial_nonstrict partial_ord_nonstrict m1 m2 in
    let c2 = M.compare_partial_nonstrict partial_ord_nonstrict m2 m3 in
    let c3 = M.compare_partial_nonstrict partial_ord_nonstrict m1 m3 in
    begin match c1, c2, c3 with
      | Comparison.Nonstrict.Incomparable, _, _
      | _, Comparison.Nonstrict.Incomparable, _
      | _, _, Comparison.Nonstrict.Incomparable
      | Leq, _, _
      | _, Leq, _
      | _, _, Leq
      | Geq, _, _
      | _, Geq, _
      | _, _, Geq
      | Lt, Gt, _
      | Gt, Lt, _ -> Q.assume_fail()  (* ignore *)
      | Eq, Eq, Eq -> true
      | Gt, Gt, Gt
      | Gt, Eq, Gt
      | Eq, Gt, Gt -> true
      | Lt, Lt, Lt
      | Lt, Eq, Lt
      | Eq, Lt, Lt -> true
      | Lt, _, Eq
      | Gt, _, Eq
      | _, Lt, Eq
      | _, Gt, Eq
      | (Eq | Lt), Lt, Gt
      | (Eq | Gt), Gt, Lt
      | Lt, Eq, Gt
      | Gt, Eq, Lt
      | Eq, Eq, (Lt | Gt)
        ->
        Q.Test.fail_reportf
          "comp %a %a %a" Comparison.Nonstrict.pp c1 Comparison.Nonstrict.pp c2 Comparison.Nonstrict.pp c3
    end
  in
  QCheck.Test.make
    ~name:"multiset_compare_partial_trans" ~long_factor:3 ~count:13_000
    (Q.triple gen1 gen1 gen1) prop

let max_seq_correct =
  let prop m =
    let l1 = M.max_seq partial_ord_nonstrict m |> Iter.map fst |> Iter.to_list in
    let l2 = M.to_list m |> List.map fst
      |> List.filter (fun x -> M.is_max partial_ord_nonstrict x m) in
    if l1=l2 then true
    else Q.Test.fail_reportf "@[max_seq %a,@ max %a@]"
        CCFormat.Dump.(list int) l1
        CCFormat.Dump.(list int) l2
  in
  Q.Test.make ~name:"multiset_max_seq" ~long_factor:5 ~count:10_000 gen1 prop

let max_is_max =
  let pp = CCFormat.to_string (M.pp CCFormat.int) in
  let gen = Q.(map M.of_list (list small_int)) in
  let gen = Q.set_print pp gen in
  let prop m =
    let f x y = Comparison.Nonstrict.of_total (Pervasives.compare x y) in
    let l = M.max f m |> M.to_list |> List.map fst in
    List.for_all (fun x -> M.is_max f x m) l
  in
  Q.Test.make
    ~name:"multiset_max_l_is_max" ~long_factor:3 ~count:1000
    gen prop

let suite =
  [ test_max;
    test_compare;
    test_cardinal_size;
    ]

let props =
  [ compare_and_partial;
    compare_partial_sym;
    compare_partial_trans;
    max_is_max;
    max_seq_correct;
  ]
