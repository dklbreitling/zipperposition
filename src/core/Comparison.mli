
(* This file is free software, part of Logtk. See file "license" for more details. *)

(** {1 Partial Ordering values} *)

(** {2 Strict partial orders} *)

type t = Lt | Eq | Gt | Incomparable

type comparison = t

val equal : t -> t -> bool

include Interfaces.PRINT with type t := t

val combine : t -> t -> t
(** Combine two partial comparisons, that are assumed to be
    compatible, ie they do not order differently if
    Incomparable is not one of the values.
    @raise Invalid_argument if the comparisons are inconsistent. *)

val opp : t -> t
(** Opposite of the relation: a R b becomes b R a *)

val to_total : t -> int
(** Conversion to a total ordering. Incomparable is translated
    to 0 (equal). *)

val of_total : int -> t
(** Conversion from a total order *)

val lexico : t -> t -> t
(** Lexicographic combination (the second is used only if the first
    is [Incomparable] *)

val (++) : t -> t -> t
(** Infix version of {!lexico} *)

type 'a comparator = 'a -> 'a -> t

val (@>>) : 'a comparator -> 'a comparator -> 'a comparator
(** Combination of comparators that work on the same values.
    Its behavior is the following:
    [(f1 @>> f2) x y] is the same as [f1 x y] if
    [f1 x y] is not [Eq]; otherwise it is the same as [f2 x y] *)

type ('a, 'b) combination
(** Lexicographic combination of comparators. It is, roughly,
    equivalent to ['a -> 'a -> 'b] *)

val last : 'a comparator -> ('a, t) combination
(** Last comparator *)

val call : ('a, 'b) combination -> 'a -> 'a -> 'b
(** Call a lexicographic combination on arguments *)

val dominates : ('a -> 'b -> t) -> 'a list -> 'b list -> bool
(** [dominates f l1 l2] returns [true] iff for all element [y] of [l2],
    there is some [x] in [l1] with [f x y = Gt] *)

module type PARTIAL_ORD = sig
  type t

  val partial_cmp : t -> t -> comparison
end

(** {2 Combined nonstrict-strict partial orders} *)

module Nonstrict : sig
  type t = Lt | Leq | Eq | Geq | Gt | Incomparable

  type comparison = t

  val equal : t -> t -> bool

  include Interfaces.PRINT with type t := t

  val opp : t -> t
  (** Opposite of the relation: a R b becomes b R a *)

  val to_total : t -> int
  (** Conversion to a total ordering. Geq, Leq, and Incomparable are translated
      to 0 (equal). *)

  val of_total : int -> t
  (** Conversion from a total order *)

  val merge_with_Geq : t -> t
  val merge_with_Leq : t -> t
  (** Combine a comparison value with Geq or Leq. *)

  val smooth : t -> t
  (** Replace Gt by Geq and Lt by Leq. *)
  val sharpen : t -> t
  (** Replace Geq by Gt and Leq by Lt. *)

  type 'a comparator = 'a -> 'a -> t

  val (@>>) : 'a comparator -> 'a comparator -> 'a comparator
  (** Combination of comparators that work on the same values. *)
end

val is_Gt_or_Geq : Nonstrict.t -> bool
val is_Lt_or_Leq : Nonstrict.t -> bool
(** Test for two constructors at once. *)

val of_nonstrict : Nonstrict.t -> t
(* Cast a nonstrict comparison value to a strict one. *)
val to_nonstrict : t -> Nonstrict.t
(* Cast a strict comparison value to a nonstrict one. *)
