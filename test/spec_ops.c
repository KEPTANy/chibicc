#include "test.h"

struct A {
  int x;
} <a: char; b: int; c: char;>;

struct B {
  int y;
} <p: long;>;

typedef struct A TA;

int main() {
  ASSERT(3, get_spec_size(struct A));
  ASSERT(3, get_spec_size(TA));
  ASSERT(1, get_spec_size(struct B));

  struct A.a va;
  struct A.b vb;
  struct A.c vc;

  va.x = 1;
  vb.x = 2;
  vc.x = 3;

  init_spec(struct A.a, &va);
  init_spec(struct A.b, &vb);
  init_spec(TA.c, &vc);

  ASSERT(spec_id_of(struct A.a), va.__spec_id);
  ASSERT(spec_id_of(struct A.b), vb.__spec_id);
  ASSERT(spec_id_of(struct A.c), vc.__spec_id);

  ASSERT(spec_id_of(struct A.a), spec_index_cmp(&va, &va));
  ASSERT(spec_id_of(struct A.b), spec_index_cmp(&vb, &vb));
  ASSERT(-1, spec_index_cmp(&va, &vb));
  ASSERT(-1, spec_index_cmp(&va, &vc));
  ASSERT(-1, spec_index_cmp(&vb, &vc));

  struct A *ga = (struct A *)&va;
  struct A *gb = (struct A *)&vb;
  ASSERT(spec_id_of(struct A.a), spec_index_cmp(ga, &va));
  ASSERT(-1, spec_index_cmp(ga, gb));

  printf("OK\n");
  return 0;
}
