/* exception.t */

#include <stdio.h>
#include <string.h>

#include "util.h"
#include "tap.h"
#include "jd_test.h"
#include "jsondata.h"

static void test_simple_throw(void) {
  JD_BEGIN {
    JD_2VARS(a, b);
    jd_set_string(a, "This is A");
    jd_throw("Oops: a=%J", a);
    jd_set_bool(b, 1);
  } JD_CATCH(e) {
    jdt_is_string(e, "Oops: a=\"This is A\"", "exception message matches");
    jd_release(e);
  }
  JD_ENDCATCH
}

static void go_deep(int depth) {
  JD_VAR(a);
  jd_printf(a, "depth=%d", depth);
  if (depth == 0)
    jd_throw("Reached the bottom");
  else
    go_deep(depth - 1);
}

static void test_deep_throw(void) {
  JD_BEGIN {
    go_deep(10);
  } JD_CATCH(e) {
    jdt_is_string(e, "Reached the bottom", "deep exception message matches");
    jd_release(e);
  }
  JD_ENDCATCH
}

static void nest_deep(int depth) {
  JD_BEGIN {
    JD_VAR(a);
    jd_printf(a, "depth=%d", depth);
    if (depth == 0)
      jd_throw("Reached the bottom");
    else
      nest_deep(depth - 1);
  }
  JD_CATCH(e) {
    jd_rethrow(e);
  }
  JD_ENDCATCH
}

static void test_deep_nest(void) {
  JD_BEGIN {
    nest_deep(10);
  }
  JD_CATCH(e) {
    jdt_is_string(e, "Reached the bottom", "nested scope exception message matches");
    jd_release(e);
  }
  JD_ENDCATCH
}

static void test_throw_in_catch(void) {
  int catch = 0, first = 0;
  JD_BEGIN {
    JD_SV(a, "first");
    jd_throw("Throw from %V block", a);
  }
  JD_CATCH(e) {
    JD_BEGIN {
      JD_SV(a, "catch");
      jd_throw("Throw from %V block", a);
    }
    JD_CATCH(e) {
      jdt_is_string(e, "Throw from catch block", "got throw catch");
      catch++;
    }
    JD_ENDCATCH
    jdt_is_string(e, "Throw from first block", "got first catch");
    first++;
  }
  JD_ENDCATCH
  is(catch, 1, "catch block exception seen");
  is(first, 1, "first block exception seen");
}

static int fib(int x) {
  JD_BEGIN {
    JD_VAR(msg);
    jd_printf(msg, "fib(%d)", x);
    if (x < 2) JD_RETURN(1);
    JD_RETURN(fib(x - 1) + fib(x - 2));
  }
  JD_END
  return 0;
}

static void test_return(void) {
  JD_BEGIN {
    is(fib(5), 8, "fib 5");
  }
  JD_END
}

static void backtrace(jd_var *out, int depth) {
  JD_BEGIN {
    if (depth > 0)
      backtrace(out, depth - 1);
    else
      jd_backtrace(out);
  }
  JD_END
}

static void test_backtrace(void) {
  JD_BEGIN {
    JD_VAR(bt);
    backtrace(bt, 10);
    /*jdt_diag("bt=%lJ", bt);*/
    is(bt->type, ARRAY, "backtrace is array");
    size_t count = jd_count(bt);
    ok(count > 10 && count < 20, "backtrace has %ld elements", (unsigned long) count);
  }
  JD_END
}

void test_main(void) {
  JD_BEGIN {
    test_simple_throw();
    test_deep_throw();
    test_deep_nest();
    test_throw_in_catch();
    test_return();
    test_backtrace();
  }
  JD_END
}


/* vim:ts=2:sw=2:sts=2:et:ft=c
 */
