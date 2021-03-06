open! Import
open! Typerep_lib.Std

module Array = Base.Array
module List  = Base.List

type 'a t = 'a list [@@deriving bin_io, typerep]

module Assoc = struct
  type ('a, 'b) t = ('a * 'b) list [@@deriving bin_io]

  let compare (type a) (type b) compare_a compare_b = [%compare: (a * b) list]
  [@@deprecated
    "[since 2016-06] This does not respect the equivalence class promised by List.Assoc. \
     Use List.compare directly if that's what you want."]

  include (List.Assoc : module type of struct include List.Assoc end
           with type ('a, 'b) t := ('a, 'b) t)
end

include (List : module type of struct include List end
         with type 'a t := 'a t
         with module Assoc := List.Assoc)

let to_string ~f t =
  Sexplib.Sexp.to_string
    (sexp_of_t (fun x -> Sexplib.Sexp.Atom x) (List.map t ~f))
;;

include Comparator.Derived(struct
    type nonrec 'a t = 'a t [@@deriving sexp_of, compare]
  end)

let gen = Base_quickcheck.Generator.list
let gen_non_empty = Base_quickcheck.Generator.list_non_empty

let gen_with_length length gen =
  Base_quickcheck.Generator.list_with_length gen ~length

let gen_permutations = Base_quickcheck.Generator.list_permutations
let obs = Base_quickcheck.Observer.list
let shrinker = Base_quickcheck.Shrinker.list
