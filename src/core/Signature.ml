
(* This file is free software, part of Logtk. See file "license" for more details. *)

(** {1 Signature} *)

type t = (((Type.t * bool) ID.Map.t) * (ID.Set.t Type.Map.t))
(** A signature maps symbols to their sort *)

let empty =
    (ID.Map.empty, Type.Map.empty)

let is_empty (sym_map, ty_map) =
  let sym_map_empty = ID.Map.is_empty sym_map in
  assert(not sym_map_empty || Type.Map.is_empty ty_map);
  sym_map_empty

let mem (sym_map, ty_map) s = ID.Map.mem s sym_map

let find_exn (sym_map, ty_map) s =
  let (t, _) = ID.Map.find s sym_map in t

let find signature s =
    try Some (find_exn signature s)
    with Not_found -> None

let find_by_type (sym_map ,ty_map) ty =
  let res = Type.Map.get_or ty ty_map ~default:ID.Set.empty in
  assert(ID.Set.for_all (fun id -> 
    let ty', _ = ID.Map.find id sym_map in
    Type.equal ty' ty) res);
  res


exception AlreadyDeclared of ID.t * Type.t * Type.t

let () = Printexc.register_printer
    (function
      | AlreadyDeclared (id, old, new_) ->
        Some (
          CCFormat.sprintf
            "@[<2>symbol %a@ is already declared with type @[%a@],@ \
             which is not compatible with @[%a@]@]"
            ID.pp id  Type.pp old Type.pp new_ )
      | _ -> None)

let declare ((sym_map, ty_map) as signature) id ty =
  try
    let ty' = find_exn signature id in
    if not (Type.equal ty ty') then raise (AlreadyDeclared (id, ty', ty))
    else signature
  with Not_found ->
    if not (InnerTerm.DB.closed (ty : Type.t :> InnerTerm.t))
    then raise (Invalid_argument "Signature.declare: non-closed type");
    let sym_map = ID.Map.add id (ty, false) sym_map in
    let ty_map = 
      let id_set = Type.Map.get_or ty ty_map ~default:ID.Set.empty in 
      Type.Map.add ty (ID.Set.add id id_set) ty_map in
    (sym_map, ty_map)

let cardinal (sym_map, _) = ID.Map.cardinal sym_map

let arity signature s =
  let ty = find_exn signature s in
  match Type.arity ty with
  | Type.NoArity ->
    failwith (CCFormat.sprintf "symbol %a has ill-formed type %a" ID.pp s Type.TPTP.pp ty)
  | Type.Arity (a,b) -> a, b

let is_ground (sym_map, _) =
  ID.Map.for_all (fun _ (ty, _) -> Type.is_ground ty) sym_map

let ty_map_of_s_map smap = 
  let ty_map = ID.Map.fold (fun id (ty, _) acc -> 
    let id_set = Type.Map.get_or ty acc ~default:ID.Set.empty in 
    Type.Map.add ty (ID.Set.add id id_set) acc) smap Type.Map.empty in
  ty_map

let merge (s_map1, _) (s_map2, _) =
  let s_map = ID.Map.merge
    (fun s t1 t2 -> match t1, t2 with
       | None, None -> assert false
       | Some (ty1, c1), Some (ty2, c2) ->
         if Type.equal ty1 ty2
         then Some (ty1, c1 && c2)
         else raise (AlreadyDeclared (s, ty1, ty2))
       | Some (s1,c1), None -> Some (s1,c1)
       | None, Some (s2,c2) -> Some (s2,c2))
    s_map1 s_map2 in
  s_map, ty_map_of_s_map s_map

let diff (s_map1, _) (s_map2, _) =
  let s_map = ID.Map.merge
    (fun _ ty1 ty2 -> match ty1, ty2 with
       | Some ty1, None -> Some ty1
       | Some _, Some _
       | None, Some _
       | None, None -> None)
    s_map1 s_map2 in
  s_map, ty_map_of_s_map s_map

let well_founded (s,_) =
  ID.Map.exists
    (fun _ (ty,_) -> match Type.arity ty with
       | Type.Arity (_, 0) -> true
       | _ -> false)
    s

let sym_in_conj s (s_map, _) =
  snd (ID.Map.get_or s s_map ~default:(Type.int, false))

let set_sym_in_conj s ((s_map,ty_map) as signature) =
  let t = find_exn signature s in
  let s_map = ID.Map.add s (t, true) s_map in
  s_map,ty_map

module Seq = struct
  let symbols (s,_) =
    ID.Map.to_seq s |> Iter.map fst

  let types (s,_) =
    ID.Map.to_seq s |> Iter.map snd |> Iter.map fst

  let to_seq (s,_) = ID.Map.to_seq s
end

let to_set s = Seq.symbols s |> ID.Set.of_seq

let to_list (s,_) = ID.Map.to_list s

let iter (s,_) f =
  ID.Map.iter f s

let fold (s,_) acc f =
  ID.Map.fold (fun s (ty,c) acc -> f acc s (ty,c)) s acc

let is_bool signature s =
  let rec is_bool ty = match Type.view ty with
    | Type.Builtin Type.Prop -> true
    | Type.Fun (_, ret) -> is_bool ret
    | Type.Forall ty' -> is_bool ty'
    | _ -> false
  in
  is_bool (find_exn signature s)

let is_not_bool signature s =
  not (is_bool signature s)

(** {2 IO} *)

let pp out s =
  let pp_pair out (s,(ty, c)) =
    Format.fprintf out "@[<hov2>%a:@ %a %B@]" ID.pp s Type.pp ty c
  in
  Format.fprintf out "{@[<hv>";
  Util.pp_seq ~sep:", " pp_pair out (Seq.to_seq s);
  Format.fprintf out "@]}";
  ()

let to_string = CCFormat.to_string pp
