open! Import

include Bin_prot.Utils.Make_binable1 (struct
    module Binable = struct
      type 'a t = 'a list [@@deriving bin_io]
    end

    type 'a t = 'a Base.Sequence.t

    let of_binable = Base.Sequence.of_list
    let to_binable = Base.Sequence.to_list
  end)

module Step = struct
  type ('a, 's) t = ('a, 's) Base.Sequence.Step.t =
    | Done
    | Skip of 's
    | Yield of 'a * 's
  [@@deriving bin_io]

  include (Base.Sequence.Step : module type of struct include Base.Sequence.Step end
           with type ('a, 's) t := ('a, 's) t)
end

module Merge_with_duplicates_element = struct
  type ('a, 'b) t = ('a, 'b) Base.Sequence.Merge_with_duplicates_element.t =
    | Left of 'a
    | Right of 'b
    | Both of 'a * 'b
  [@@deriving bin_io]

  include (Base.Sequence.Merge_with_duplicates_element
           : module type of struct include Base.Sequence.Merge_with_duplicates_element end
           with type ('a, 'b) t := ('a, 'b) t)
end

include (Base.Sequence
         : module type of struct include Base.Sequence end
         with module Step := Base.Sequence.Step
          and module Merge_with_duplicates_element := Base.Sequence.Merge_with_duplicates_element)

module Merge_all_state = struct
  type 'a t = {
    heap            : ('a * 'a Base.Sequence.t) Fheap.t;
    not_yet_in_heap : 'a Base.Sequence.t list;
  } [@@deriving fields]

  let create = Fields.create
end

let merge_all seqs ~compare =
  unfold_step
    ~init:(Merge_all_state.create
             ~heap:(Fheap.create ~cmp:(Base.Comparable.lift compare ~f:fst))
             ~not_yet_in_heap:seqs)
    ~f:(fun { heap; not_yet_in_heap } ->
      match not_yet_in_heap with
      | seq :: not_yet_in_heap ->
        begin
          match Expert.next_step seq with
          | Done             -> Skip { not_yet_in_heap; heap }
          | Skip        seq  -> Skip { not_yet_in_heap = seq :: not_yet_in_heap; heap }
          | Yield (elt, seq) -> Skip { not_yet_in_heap; heap = Fheap.add heap (elt, seq) }
        end
      | [] ->
        begin
          match Fheap.pop heap with
          | None                    -> Done
          | Some ((elt, seq), heap) ->
            Yield (elt, { heap; not_yet_in_heap = [seq] })
        end)
;;
