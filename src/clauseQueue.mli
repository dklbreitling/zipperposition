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

(** Heuristic selection of clauses, using queues. Note that some
    queues do not need accept all clauses, as long as one of them does
    (for completeness). Anyway, a fifo queue should always be present,
    and presents this property. *)

open Types

(** A priority queue of clauses, purely functional *)
class type queue =
  object
    method add : hclause -> queue
    method add_list : hclause list -> queue
    method is_empty: bool
    method take_first : (queue * hclause)
    method clean : Clauses.CSet.t -> queue    (** remove all clauses that are not in the set *)
    method name : string
  end

(** select by increasing age (for fairness) *)
val fifo : queue

(** select by increasing weight of clause *)
val clause_weight : queue

(** only select goals (clauses with only negative lits) *)
val goals : queue

(** only select ground clauses *)
val ground : queue

(** only select positive unit clauses *)
val pos_unit_clauses : queue

(** default combination of heuristics *)
val default_queues : (queue * int) list

val pp_queue : Format.formatter -> queue -> unit
val pp_queues : Format.formatter -> (queue * int) list -> unit

