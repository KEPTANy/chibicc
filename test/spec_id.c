#include "test.h"

struct A {
  int x;
} <a: char; b: int; c: char;>;

struct B {
  int y;
} <p: long;>;

typedef struct A TA;

int ctor_id;
int ctor_ok;

__attribute__((constructor)) void after_spec_ctors(void) {
  ctor_id = spec_id_of(struct A.a);
  ctor_ok = ctor_id != 0;
}

int main() {
  int a = spec_id_of(struct A.a);
  int b = spec_id_of(struct A.b);
  int c = spec_id_of(struct A.c);
  int p = spec_id_of(struct B.p);
  int a2 = spec_id_of(TA.a);

  ASSERT(1, a != 0);
  ASSERT(1, b != 0);
  ASSERT(1, c != 0);
  ASSERT(1, p != 0);

  ASSERT(1, a == spec_id_of(struct A.a));
  ASSERT(1, a == a2);
  ASSERT(1, a != b);
  ASSERT(1, a != c);
  ASSERT(1, b != c);

  // Same payload type still gets a distinct id.
  ASSERT(1, spec_id_of(struct A.a) != spec_id_of(struct A.c));

  // Independent generalization has its own counter; id 1 is allowed.
  ASSERT(1, p != 0);

  struct A.a va;
  va.__spec_id = spec_id_of(struct A.a);
  va.x = 7;
  ASSERT(va.__spec_id, spec_id_of(struct A.a));
  ASSERT(7, va.x);

  ASSERT(1, ctor_ok);
  ASSERT(a, ctor_id);

  // Nested specialization is a different type (and usually a different id).
  struct N {
    int n;
  } <inner: struct N; leaf: char;>;
  int n1 = spec_id_of(struct N.inner);
  int n2 = spec_id_of(struct N.inner.leaf);
  int n3 = spec_id_of(struct N.leaf);
  ASSERT(1, n1 != 0);
  ASSERT(1, n2 != 0);
  ASSERT(1, n3 != 0);
  ASSERT(1, n1 != n2);
  ASSERT(1, n2 != n3);
  ASSERT(1, n1 != n3);

  printf("OK\n");
  return 0;
}
