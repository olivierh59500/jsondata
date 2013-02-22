/* jd_map.c */

#include "jd_private.h"
#include "jsondata.h"

typedef int (*filter_function)(jd_var *out, jd_var *cl, jd_var *in);

static jd_var *filter(jd_var *out, jd_var *cl, filter_function ff, jd_var *in);

#define IS_FILTERED(t) (JD_IS_SIMPLE(t) || (t) == CLOSURE || (t) == OBJECT)

static int map_filter(jd_var *out, jd_var *cl, jd_var *in) {
  jd_eval(cl, out, in);
  return 1;
}

static int grep_filter(jd_var *out, jd_var *cl, jd_var *in) {
  int ok;

  JD_BEGIN {
    JD_VAR(rv);
    jd_eval(cl, rv, in);
    ok = jd_test(rv);
    if (ok) jd_assign(out, in);
  }
  JD_END

  return ok;
}

static jd_var *filter_array(jd_var *out, jd_var *cl, filter_function ff, jd_var *in) {
  JD_BEGIN {
    size_t count = jd_count(in);
    JD_VAR(rv);
    unsigned i;

    jd_set_array(out, count);
    for (i = 0; i < count; i++) {
      jd_var *v = jd_get_idx(in, i);
      if (IS_FILTERED(v->type)) {
        if (ff(rv, cl, v)) jd_assign(jd_push(out, 1), rv);
        jd_release(rv);
      }
      else {
        filter(jd_push(out, 1), cl, ff, v);
      }
    }
  }
  JD_END

  return out;
}

static jd_var *filter_hash(jd_var *out, jd_var *cl, filter_function ff, jd_var *in) {
  JD_BEGIN {
    size_t count = jd_count(in);
    JD_2VARS(rv, keys);
    unsigned i;

    jd_keys(in, keys);
    jd_set_hash(out, count);
    for (i = 0; i < count; i++) {
      jd_var *k = jd_get_idx(keys, i);
      jd_var *v = jd_get_key(in, k, 0);
      if (IS_FILTERED(v->type)) {
        if (ff(rv, cl, v)) jd_assign(jd_get_key(out, k, 1), rv);
        jd_release(rv);
      }
      else {
        filter(jd_get_key(out, k, 1), cl, ff, v);
      }
    }
  }
  JD_END

  return out;
}

static jd_var *filter_scalar(jd_var *out, jd_var *cl, filter_function ff, jd_var *in) {
  JD_BEGIN {
    JD_VAR(rv);
    if (ff(rv, cl, in)) jd_assign(out, rv);
    else jd_set_void(out);
  }
  JD_END
  return out;
}

static jd_var *filter(jd_var *out, jd_var *cl, filter_function ff, jd_var *in) {
  switch (in->type) {
  case ARRAY:
    return filter_array(out, cl, ff, in);
  case HASH:
    return filter_hash(out, cl, ff, in);
  default:
    return filter_scalar(out, cl, ff, in);
  }
}

jd_var *jd_map(jd_var *out, jd_var *func, jd_var *in) {
  return filter(out, func, map_filter, in);
}

jd_var *jd_grep(jd_var *out, jd_var *func, jd_var *in) {
  return filter(out, func, grep_filter, in);
}

/* vim:ts=2:sw=2:sts=2:et:ft=c
 */
