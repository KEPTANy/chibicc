#ifndef PPP_COMPAT_H
#define PPP_COMPAT_H

#include <stdlib.h>

// Heap-allocate a specialization and tag it. chibicc only has init_spec,
// which tags storage the caller already owns.
#define create_spec(T) ({ T *p__ = malloc(sizeof(T)); init_spec(T, p__); (void *)p__; })

#endif
