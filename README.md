# chibicc with procedural-parametric extensions

This project extends [Rui Ueyama's chibicc](https://github.com/rui314/chibicc), an educational C11 compiler,
with support for several features proposed [there](https://softcraft.ru/ppp/ppc/).

## Generalizations and specializations

A generalization is best described as a mix of a struct and a tagged union with across-TU extension support:

```c
typedef struct Figure {
} <rect: Rectangle; trian: Triangle;> Figure;
```

Etries in `<>` are called specializations. `Figure.rect` is a complete type whose layout
is the generalization's fields, then an integer tag, then the payload:

```c
struct {
  /* fields of Figure, if any */
  int __spec_id;
  Rectangle @;
};
```

`@` is an ordinary member that holds the payload.
Nested specializations chain with dots: `Gen.spec.inner`.

The list may be empty (`<>`) and filled in later. A new specialization is
appended with `+`:

```c
typedef struct Figure {} <> Figure;

Figure + <rect: Rectangle;>;
Figure + <trian: Triangle;>;
```

The same specialization declared in several translation units is one type.
The linker merges them.

A specialization pointer may be used wherever a pointer to its generalization
is expected. The other direction needs an explicit cast.

## Tags

Each specialization of a generalization gets a distinct `__spec_id`, assigned
by a constructor that runs before `main`. The assignment is stable for a given
link, but the numbers themselves are not source-level constants: they depend
on how many specializations were merged.

Objects are not tagged automatically. After declaring a specialization
`init_spec` can be used to fill the `__spec_id` with the specialization's value that
was computed after constructiors:

```c
struct Figure.rect r;
init_spec(Figure.rect, &r);
r.@.x = 3;
```

## Builtins

| expression | meaning |
| --- | --- |
| `spec_id_of(Figure.rect)` | the integer id of that specialization |
| `init_spec(Figure.rect, p)` | write that id into `p->__spec_id` |
| `get_spec_size(Figure)` | how many specializations `Figure` has after linking |
| `spec_index_cmp(p, q)` | their common id, or `-1` if the tags differ |

`p` and `q` must be pointers to the same generalization (or to one of its
specializations). `get_spec_size` counts from one: an empty generalization
reports `0`, and the first specialization is `1`.

## Parametric functions

A parametric function is a family of ordinary functions that share a name and
are selected by the tag of one specialized argument. That argument is written
in `<>` and, at the ABI level, is passed first:

```c
void FigureOut<Figure *f>(FILE *ofst) {} // default
void FigureOut<Figure.rect *f>(FILE *ofst) { /* ... */ }
void FigureOut<Figure.trian *f>(FILE *ofst) { /* ... */ }

FigureOut<fp>(stdout);
```

A variation whose specialized parameter is the generalization itself is the
default. Any specialization without a variation of its own falls through to it.

Calls go through a table of function pointers, allocated at constructor time and
indexed by `__spec_id`. The specialized argument is evaluated once and reused
both as the index and as the first parameter.

Several specialized parameters (multimethods) are not supported.

## Build

```sh
make
```

`examples/` is the easier place to see the features used together: tagged
figures in a container, a decorator, a type test, a recursive composite, and
integer payloads split across files.
