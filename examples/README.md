# Examples

Five programs from the upstream procedural-parametric collection, adapted
to chibicc. `make examples` builds and checks all of them.

| directory | what it shows |
| --- | --- |
| `figures` | Tagged specializations and parametric `FigureIn` / `FigureOut`, dispatched through a container. The baseline. |
| `decorator` | A specialization whose payload holds a `Figure *`. Input and output recurse through that pointer. |
| `rect-only` | A parametric predicate (`isFigureRectangle`) used as a filter: default returns false, the rectangle specialization returns true. |
| `composite` | A figure specialized as a container of figures. Nested composites, stack `init_spec`, recursive dispatch. |
| `int-payload` | Integer payloads, specializations declared across several translation units, and a default implementation. |

Each directory has its sources, a `build.sh`, and `expected.txt`. Programs that
read a file also have `data/`. `ppp-compat.h` defines `create_spec` in terms of
`malloc` and `init_spec`.
