#include "test.h"

struct A {
  int x;
} <a: int; b: char; c: long;>;

typedef struct A TA;

struct B {
  int y;
} <p: int;>;

// One variation per specialization, plus a default for the ones that have
// none. The specialized parameter is written in <> and passed first.
int Value<struct A.a *v>(void) {
  return v->@;
}

int Value<TA.b *v>(void) {
  return v->@;
}

int Value<struct A *v>(void) {
  return -v->x;
}

// Variations also take ordinary parameters and return values.
int Sum<struct A.a *v>(int lhs, int rhs) {
  return v->@ + lhs + rhs;
}

int Sum<struct A *v>(int lhs, int rhs) {
  return lhs + rhs;
}

// A second family over an unrelated generalization.
int Tag<struct B.p *v>(void) {
  return v->@ * 2;
}

int ctor_value;

__attribute__((constructor)) void after_param_func_ctors(void) {
  struct A.a a;
  init_spec(struct A.a, &a);
  a.@ = 12;
  ctor_value = Value<&a>();
}

int main() {
  struct A.a a;
  struct A.b b;
  struct A.c c;
  struct B.p p;

  init_spec(struct A.a, &a);
  init_spec(struct A.b, &b);
  init_spec(TA.c, &c);
  init_spec(struct B.p, &p);

  a.@ = 7;
  b.@ = 'z';
  c.x = 3;
  p.@ = 21;

  ASSERT(7, Value<&a>());
  ASSERT('z', Value<&b>());

  // struct A.c has no variation of its own, so it reaches the default.
  ASSERT(-3, Value<&c>());

  // Dispatching on a generalization pointer picks the same variation.
  struct A *ga = (struct A *)&a;
  struct A *gc = (struct A *)&c;
  ASSERT(7, Value<ga>());
  ASSERT(-3, Value<gc>());

  ASSERT(17, Sum<&a>(4, 6));
  ASSERT(10, Sum<&c>(4, 6));

  ASSERT(42, Tag<&p>());

  // The specialized argument is evaluated exactly once.
  struct A.a arr[2];
  init_spec(struct A.a, &arr[0]);
  init_spec(struct A.a, &arr[1]);
  arr[0].@ = 100;
  arr[1].@ = 200;
  int i = 0;
  ASSERT(100, Value<&arr[i++]>());
  ASSERT(1, i);

  // A parenthesized specialized argument may be an arbitrary expression.
  ASSERT(200, Value<(i ? &arr[1] : &arr[0])>());

  // The table is filled before user constructors run.
  ASSERT(12, ctor_value);

  printf("OK\n");
  return 0;
}
