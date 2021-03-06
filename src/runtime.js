///////// CORE_KERNEL

//Provides: core_array_unsafe_int_blit
//Requires: caml_array_blit
var core_array_unsafe_int_blit = caml_array_blit
//Provides: core_array_unsafe_float_blit
//Requires: caml_array_blit
var core_array_unsafe_float_blit = caml_array_blit

//Provides: bigstring_realloc
//Requires: caml_invalid_argument, caml_ba_create_from, bigstring_destroy_stub
function bigstring_realloc(bigstring, size) {
    if (bigstring.data2 != null) {
        caml_invalid_argument("Bigstring.unsafe_destroy_and_resize: unsupported kind");
    }

    if (bigstring.hasOwnProperty('__is_deallocated')) {
        caml_invalid_argument("bigstring_realloc: bigstring is already deallocated");
    }

    var new_data = new bigstring.data.__proto__.constructor(size);
    new_data.set(bigstring.data.slice(0, size));
    var new_bigstring =
        caml_ba_create_from(new_data, null, bigstring.data_type, bigstring.kind,
                            bigstring.layout, [size]);

    bigstring_destroy_stub(bigstring);

    return new_bigstring;
}

//Provides: core_kernel_time_ns_gettime_or_zero
//Requires: caml_int64_mul, caml_int64_of_float, caml_int64_of_int32
var ms_to_nano = caml_int64_of_int32(1000*1000);
function core_kernel_time_ns_gettime_or_zero(){
  var ms = Date.now();
  // multiple by two - int63 integers are shifted to the left
  var ms_i63 = caml_int64_of_float(ms*2);
  return caml_int64_mul(ms_i63,ms_to_nano);
}
//Provides: core_kernel_time_ns_format
//Requires: caml_to_js_string, caml_js_to_string
function core_kernel_time_ns_format(time,format){
  var d = new Date(time * 1000);
  var formatjs = caml_to_js_string(format);
  var jstring = joo_global_object.strftime(formatjs, d);
  return caml_js_to_string(jstring);
}

//Provides: core_kernel_gc_compactions
function core_kernel_gc_compactions () { return 0 }
//Provides: core_kernel_gc_heap_chunks
function core_kernel_gc_heap_chunks () { return 0 }
//Provides: core_kernel_gc_heap_words
function core_kernel_gc_heap_words () { return 0 }
//Provides: core_kernel_gc_major_collections
function core_kernel_gc_major_collections () { return 0 }
//Provides: core_kernel_gc_major_plus_minor_words
function core_kernel_gc_major_plus_minor_words () { return 0 }
//Provides: core_kernel_gc_major_words
function core_kernel_gc_major_words () { return 0 }
//Provides: core_kernel_gc_minor_collections
function core_kernel_gc_minor_collections () { return 0 }
//Provides: core_kernel_gc_minor_words
function core_kernel_gc_minor_words () { return 0 }
//Provides: core_kernel_gc_promoted_words
function core_kernel_gc_promoted_words () { return 0 }
//Provides: core_kernel_gc_top_heap_words
function core_kernel_gc_top_heap_words () { return 0 }

//Provides: internalhash_fold_bigstring
//Requires: caml_hash_mix_bigstring
var internalhash_fold_bigstring = caml_hash_mix_bigstring

//Provides: generated_build_info
//Requires: caml_read_file_content, caml_new_string
function generated_build_info () {
  try {
    return caml_read_file_content("/static/build_info.sexp");
  } catch (e) {
    return caml_new_string(
      '('
        + '(username "")'
        + '(hostname "")'
        + '(kernel   "")'
        + '(build_time "1970-01-01 00:00:00Z")'
        + '(x_library_inlining false)'
        + '(portable_int63 true)'
        + '(dynlinkable_code false)'
        + '(ocaml_version "")'
        + '(executable_path "")'
        + '(build_system "")'
        + ')'
    );
  }
}


//Provides: generated_hg_version
//Requires: caml_read_file_content, caml_new_string
function generated_hg_version () {
  try {
    return caml_read_file_content("/static/hg_version.out");
  } catch (e) {
    return caml_new_string("NO_VERSION_UTIL");
  }
}

//Provides: Core_kernel_heap_block_is_heap_block
function Core_kernel_heap_block_is_heap_block(x){
  return +(x instanceof Array);
}
