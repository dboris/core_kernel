open! Import

module Sexp = Sexplib.Sexp

include Base.Sexp

include (Sexp : module type of struct include Sexp end with type t := t)

include (struct
  type t = Base.Sexp.t = Atom of string | List of t list [@@deriving bin_io]
end : sig
           type t [@@deriving bin_io]
         end with type t := t)

module O = struct
  type sexp = Sexp.t = Atom of string | List of t list
end

module Sexp_maybe = struct

  type sexp = t [@@deriving bin_io, compare, hash]             (* avoid recursive type *)

  (* to satisfy pa_compare *)
  module Error = struct
    include Error
    include Comparable.Poly (Error)
  end

  type 'a t = ('a, sexp * Error.t) Result.t [@@deriving bin_io, compare, hash]

  let sexp_of_t sexp_of_a t =
    match t with
    | Result.Ok a -> sexp_of_a a
    | Result.Error (sexp, err) ->
      Sexp.List [
        Sexp.Atom "sexp_parse_error";
        sexp;
        Error.sexp_of_t err;
      ]

  let t_of_sexp a_of_sexp sexp =
    match sexp with
    | Sexp.List [ Sexp.Atom "sexp_parse_error"; sexp; _ ]
    | sexp ->
      try Result.Ok (a_of_sexp sexp)
      with exn -> Result.Error (sexp, Error.of_exn exn)

end

module With_text = struct
  open Result.Export

  type 'a t =
    { value: 'a
    ; text: string
    }
  [@@deriving bin_io]

  let sexp_of_t _ t = Sexp.Atom t.text

  let of_text value_of_sexp ?(filename="") text =
    match
      Or_error.try_with (fun () ->
        Sexp.of_string_conv text value_of_sexp)
    with
    | Ok (`Result value) -> Ok { value; text }
    | Error _ as err -> err
    | Ok (`Error (exn, annotated)) ->
      Error (Error.of_exn (Sexp.Annotated.get_conv_exn annotated ~file:filename ~exc:exn))

  let t_of_sexp a_of_sexp sexp =
    match sexp with
    | List _ ->
      of_sexp_error
        "With_text.t should be stored as an atom, but instead a list was found." sexp
    | Atom text ->
      of_text a_of_sexp text |> Or_error.ok_exn

  let text  t = t.text
  let value t = t.value

  let of_value sexp_of_value value =
    let text = sexp_of_value value |> Sexp.to_string_hum in
    { value; text }
end

type 'a no_raise = 'a [@@deriving bin_io, sexp]

let sexp_of_no_raise sexp_of_a a =
  try sexp_of_a a
  with exn ->
  try List [ Atom "failure building sexp"; sexp_of_exn exn ]
  with _ -> Atom "could not build sexp for exn raised when building sexp for value"
;;

include Comparable.Extend(Base.Sexp)(Base.Sexp)

let of_sexp_allow_extra_fields of_sexp sexp =
  let r = Sexplib.Conv.record_check_extra_fields in
  let prev = !r in
  Exn.protect ~finally:(fun () -> r := prev)
    ~f:(fun () -> r := false; of_sexp sexp)

let gen = Base_quickcheck.Generator.sexp
let obs = Base_quickcheck.Observer.sexp
let shrinker = Base_quickcheck.Shrinker.sexp
