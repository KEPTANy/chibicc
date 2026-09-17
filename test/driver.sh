#!/bin/bash
chibicc=$1

tmp=`mktemp -d /tmp/chibicc-test-XXXXXX`
trap 'rm -rf $tmp' INT TERM HUP EXIT
echo > $tmp/empty.c

check() {
    if [ $? -eq 0 ]; then
        echo "testing $1 ... passed"
    else
        echo "testing $1 ... failed"
        exit 1
    fi
}

# -o
rm -f $tmp/out
./chibicc -c -o $tmp/out $tmp/empty.c
[ -f $tmp/out ]
check -o

# --help
$chibicc --help 2>&1 | grep -q chibicc
check --help

# -S
echo 'int main() {}' | $chibicc -S -o- -xc - | grep -q 'main:'
check -S

# Default output file
rm -f $tmp/out.o $tmp/out.s
echo 'int main() {}' > $tmp/out.c
(cd $tmp; $OLDPWD/$chibicc -c out.c)
[ -f $tmp/out.o ]
check 'default output file'

(cd $tmp; $OLDPWD/$chibicc -c -S out.c)
[ -f $tmp/out.s ]
check 'default output file'

# Multiple input files
rm -f $tmp/foo.o $tmp/bar.o
echo 'int x;' > $tmp/foo.c
echo 'int y;' > $tmp/bar.c
(cd $tmp; $OLDPWD/$chibicc -c $tmp/foo.c $tmp/bar.c)
[ -f $tmp/foo.o ] && [ -f $tmp/bar.o ]
check 'multiple input files'

rm -f $tmp/foo.s $tmp/bar.s
echo 'int x;' > $tmp/foo.c
echo 'int y;' > $tmp/bar.c
(cd $tmp; $OLDPWD/$chibicc -c -S $tmp/foo.c $tmp/bar.c)
[ -f $tmp/foo.s ] && [ -f $tmp/bar.s ]
check 'multiple input files'

# Run linker
rm -f $tmp/foo
echo 'int main() { return 0; }' | $chibicc -o $tmp/foo -xc -xc -
$tmp/foo
check linker

rm -f $tmp/foo
echo 'int bar(); int main() { return bar(); }' > $tmp/foo.c
echo 'int bar() { return 42; }' > $tmp/bar.c
$chibicc -o $tmp/foo $tmp/foo.c $tmp/bar.c
$tmp/foo
[ "$?" = 42 ]
check linker

# a.out
rm -f $tmp/a.out
echo 'int main() {}' > $tmp/foo.c
(cd $tmp; $OLDPWD/$chibicc foo.c)
[ -f $tmp/a.out ]
check a.out

# -E
echo foo > $tmp/out
echo "#include \"$tmp/out\"" | $chibicc -E -xc - | grep -q foo
check -E

echo foo > $tmp/out1
echo "#include \"$tmp/out1\"" | $chibicc -E -o $tmp/out2 -xc -
cat $tmp/out2 | grep -q foo
check '-E and -o'

# -I
mkdir $tmp/dir
echo foo > $tmp/dir/i-option-test
echo "#include \"i-option-test\"" | $chibicc -I$tmp/dir -E -xc - | grep -q foo
check -I

# -D
echo foo | $chibicc -Dfoo -E -xc - | grep -q 1
check -D

# -D
echo foo | $chibicc -Dfoo=bar -E -xc - | grep -q bar
check -D

# -U
echo foo | $chibicc -Dfoo=bar -Ufoo -E -xc - | grep -q foo
check -U

# ignored options
$chibicc -c -O -Wall -g -std=c11 -ffreestanding -fno-builtin \
         -fno-omit-frame-pointer -fno-stack-protector -fno-strict-aliasing \
         -m64 -mno-red-zone -w -o /dev/null $tmp/empty.c
check 'ignored options'

# BOM marker
printf '\xef\xbb\xbfxyz\n' | $chibicc -E -o- -xc - | grep -q '^xyz'
check 'BOM marker'

# Inline functions
echo 'inline void foo() {}' > $tmp/inline1.c
echo 'inline void foo() {}' > $tmp/inline2.c
echo 'int main() { return 0; }' > $tmp/inline3.c
$chibicc -o /dev/null $tmp/inline1.c $tmp/inline2.c $tmp/inline3.c
check inline

echo 'extern inline void foo() {}' > $tmp/inline1.c
echo 'int foo(); int main() { foo(); }' > $tmp/inline2.c
$chibicc -o /dev/null $tmp/inline1.c $tmp/inline2.c
check inline

echo 'static inline void f1() {}' | $chibicc -o- -S -xc - | grep -v -q f1:
check inline

echo 'static inline void f1() {} void foo() { f1(); }' | $chibicc -o- -S -xc - | grep -q f1:
check inline

echo 'static inline void f1() {} static inline void f2() { f1(); } void foo() { f1(); }' | $chibicc -o- -S -xc - | grep -q f1:
check inline

echo 'static inline void f1() {} static inline void f2() { f1(); } void foo() { f1(); }' | $chibicc -o- -S -xc - | grep -v -q f2:
check inline

echo 'static inline void f1() {} static inline void f2() { f1(); } void foo() { f2(); }' | $chibicc -o- -S -xc - | grep -q f1:
check inline

echo 'static inline void f1() {} static inline void f2() { f1(); } void foo() { f2(); }' | $chibicc -o- -S -xc - | grep -q f2:
check inline

echo 'static inline void f2(); static inline void f1() { f2(); } static inline void f2() { f1(); } void foo() {}' | $chibicc -o- -S -xc - | grep -v -q f1:
check inline

echo 'static inline void f2(); static inline void f1() { f2(); } static inline void f2() { f1(); } void foo() {}' | $chibicc -o- -S -xc - | grep -v -q f2:
check inline

echo 'static inline void f2(); static inline void f1() { f2(); } static inline void f2() { f1(); } void foo() { f1(); }' | $chibicc -o- -S -xc - | grep -q f1:
check inline

echo 'static inline void f2(); static inline void f1() { f2(); } static inline void f2() { f1(); } void foo() { f1(); }' | $chibicc -o- -S -xc - | grep -q f2:
check inline

echo 'static inline void f2(); static inline void f1() { f2(); } static inline void f2() { f1(); } void foo() { f2(); }' | $chibicc -o- -S -xc - | grep -q f1:
check inline

echo 'static inline void f2(); static inline void f1() { f2(); } static inline void f2() { f1(); } void foo() { f2(); }' | $chibicc -o- -S -xc - | grep -q f2:
check inline

# -idirafter
mkdir -p $tmp/dir1 $tmp/dir2
echo foo > $tmp/dir1/idirafter
echo bar > $tmp/dir2/idirafter
echo "#include \"idirafter\"" | $chibicc -I$tmp/dir1 -I$tmp/dir2 -E -xc - | grep -q foo
check -idirafter
echo "#include \"idirafter\"" | $chibicc -idirafter $tmp/dir1 -I$tmp/dir2 -E -xc - | grep -q bar
check -idirafter

# -fcommon
echo 'int foo;' | $chibicc -S -o- -xc - | grep -q '\.comm foo'
check '-fcommon (default)'

echo 'int foo;' | $chibicc -fcommon -S -o- -xc - | grep -q '\.comm foo'
check '-fcommon'

# -fno-common
echo 'int foo;' | $chibicc -fno-common -S -o- -xc - | grep -q '^foo:'
check '-fno-common'

# -include
echo foo > $tmp/out.h
echo bar | $chibicc -include $tmp/out.h -E -o- -xc - | grep -q -z 'foo.*bar'
check -include
echo NULL | $chibicc -Iinclude -include stdio.h -E -o- -xc - | grep -q 0
check -include

# -x
echo 'int x;' | $chibicc -c -xc -o $tmp/foo.o -
check -xc
echo 'x:' | $chibicc -c -x assembler -o $tmp/foo.o -
check '-x assembler'

echo 'int x;' > $tmp/foo.c
$chibicc -c -x assembler -x none -o $tmp/foo.o $tmp/foo.c
check '-x none'

# -E
echo foo | $chibicc -E - | grep -q foo
check -E

# .a file
echo 'void foo() {}' | $chibicc -c -xc -o $tmp/foo.o -
echo 'void bar() {}' | $chibicc -c -xc -o $tmp/bar.o -
ar rcs $tmp/foo.a $tmp/foo.o $tmp/bar.o
echo 'void foo(); void bar(); int main() { foo(); bar(); }' > $tmp/main.c
$chibicc -o $tmp/foo $tmp/main.c $tmp/foo.a
check '.a'

# .so file
echo 'void foo() {}' | cc -fPIC -c -xc -o $tmp/foo.o -
echo 'void bar() {}' | cc -fPIC -c -xc -o $tmp/bar.o -
cc -shared -o $tmp/foo.so $tmp/foo.o $tmp/bar.o
echo 'void foo(); void bar(); int main() { foo(); bar(); }' > $tmp/main.c
$chibicc -o $tmp/foo $tmp/main.c $tmp/foo.so
check '.so'

$chibicc -hashmap-test
check 'hashmap'

# -M
echo '#include "out2.h"' > $tmp/out.c
echo '#include "out3.h"' >> $tmp/out.c
touch $tmp/out2.h $tmp/out3.h
$chibicc -M -I$tmp $tmp/out.c | grep -q -z '^out.o: .*/out\.c .*/out2\.h .*/out3\.h'
check -M

# -MF
$chibicc -MF $tmp/mf -M -I$tmp $tmp/out.c
grep -q -z '^out.o: .*/out\.c .*/out2\.h .*/out3\.h' $tmp/mf
check -MF

# -MP
$chibicc -MF $tmp/mp -MP -M -I$tmp $tmp/out.c
grep -q '^.*/out2.h:' $tmp/mp
check -MP
grep -q '^.*/out3.h:' $tmp/mp
check -MP

# -MT
$chibicc -MT foo -M -I$tmp $tmp/out.c | grep -q '^foo:'
check -MT
$chibicc -MT foo -MT bar -M -I$tmp $tmp/out.c | grep -q '^foo bar:'
check -MT

# -MD
echo '#include "out2.h"' > $tmp/md2.c
echo '#include "out3.h"' > $tmp/md3.c
(cd $tmp; $OLDPWD/$chibicc -c -MD -I. md2.c md3.c)
grep -q -z '^md2.o:.* md2\.c .* ./out2\.h' $tmp/md2.d
check -MD
grep -q -z '^md3.o:.* md3\.c .* ./out3\.h' $tmp/md3.d
check -MD

$chibicc -c -MD -MF $tmp/md-mf.d -I. $tmp/md2.c
grep -q -z '^md2.o:.*md2\.c .*/out2\.h' $tmp/md-mf.d
check -MD

echo 'extern int bar; int foo() { return bar; }' | $chibicc -fPIC -xc -c -o $tmp/foo.o -
cc -shared -o $tmp/foo.so $tmp/foo.o
echo 'int foo(); int bar=3; int main() { foo(); }' > $tmp/main.c
$chibicc -o $tmp/foo $tmp/main.c $tmp/foo.so
check -fPIC

# #include_next
mkdir -p $tmp/next1 $tmp/next2 $tmp/next3
echo '#include "file1.h"' > $tmp/file.c
echo '#include_next "file1.h"' > $tmp/next1/file1.h
echo '#include_next "file2.h"' > $tmp/next2/file1.h
echo 'foo' > $tmp/next3/file2.h
$chibicc -I$tmp/next1 -I$tmp/next2 -I$tmp/next3 -E $tmp/file.c | grep -q foo
check '#include_next'

# -static
echo 'extern int bar; int foo() { return bar; }' > $tmp/foo.c
echo 'int foo(); int bar=3; int main() { foo(); }' > $tmp/bar.c
$chibicc -static -o $tmp/foo $tmp/foo.c $tmp/bar.c
check -static
file $tmp/foo | grep -q 'statically linked'
check -static

# -shared
echo 'extern int bar; int foo() { return bar; }' > $tmp/foo.c
echo 'int foo(); int bar=3; int main() { foo(); }' > $tmp/bar.c
$chibicc -fPIC -shared -o $tmp/foo.so $tmp/foo.c $tmp/bar.c
check -shared

# -L
echo 'extern int bar; int foo() { return bar; }' > $tmp/foo.c
$chibicc -fPIC -shared -o $tmp/libfoobar.so $tmp/foo.c
echo 'int foo(); int bar=3; int main() { foo(); }' > $tmp/bar.c
$chibicc -o $tmp/foo $tmp/bar.c -L$tmp -lfoobar
check -L

# -Wl,
echo 'int foo() {}' | $chibicc -c -o $tmp/foo.o -xc -
echo 'int foo() {}' | $chibicc -c -o $tmp/bar.o -xc -
echo 'int main() {}' | $chibicc -c -o $tmp/baz.o -xc -
cc -Wl,-z,muldefs,--gc-sections -o $tmp/foo $tmp/foo.o $tmp/bar.o $tmp/baz.o
check -Wl,

# -Xlinker
echo 'int foo() {}' | $chibicc -c -o $tmp/foo.o -xc -
echo 'int foo() {}' | $chibicc -c -o $tmp/bar.o -xc -
echo 'int main() {}' | $chibicc -c -o $tmp/baz.o -xc -
cc -Xlinker -z -Xlinker muldefs -Xlinker --gc-sections -o $tmp/foo $tmp/foo.o $tmp/bar.o $tmp/baz.o
check -Xlinker

# Cross-TU specialization ID merge
cat > $tmp/spec1.c << 'EOF'
struct A { int x; } <a: char; b: int;>;
int tag_a1(void) { return spec_id_of(struct A.a); }
int tag_b(void) { return spec_id_of(struct A.b); }
EOF
cat > $tmp/spec2.c << 'EOF'
struct A { int x; } <a: char;>;
struct A + <c: long;>;
int tag_a1(void);
int tag_b(void);
int tag_a2(void) { return spec_id_of(struct A.a); }
int tag_c(void) { return spec_id_of(struct A.c); }
int main(void) {
  int a1 = tag_a1();
  int a2 = tag_a2();
  int b = tag_b();
  int c = tag_c();
  if (!a1 || !a2 || !b || !c)
    return 1;
  if (a1 != a2)
    return 2;
  if (a1 == b || a1 == c || b == c)
    return 3;
  return 0;
}
EOF
$chibicc -o $tmp/specmerge $tmp/spec1.c $tmp/spec2.c
$tmp/specmerge
check 'spec id merge'

# spec_id_of is stable, works on typedefs, and is assigned before user constructors
cat > $tmp/spec_single.c << 'EOF'
struct A { int x; } <a: char; b: int;>;
typedef struct A TA;
int seen;
__attribute__((constructor)) void user_ctor(void) {
    seen = spec_id_of(struct A.a);
}
int main(void) {
    int a = spec_id_of(struct A.a);
    int b = spec_id_of(struct A.b);
    int a2 = spec_id_of(TA.a);
    if (!a || !b || !seen)
        return 1;
    if (a != a2 || a != seen || a == b)
        return 2;
    return 0;
}
EOF
$chibicc -o $tmp/specsingle $tmp/spec_single.c
$tmp/specsingle
check 'spec_id_of single file'

# Three TUs share the same specialization
cat > $tmp/spec3a.c << 'EOF'
struct A { int x; } <a: char;>;
int id_a(void) { return spec_id_of(struct A.a); }
EOF
cat > $tmp/spec3b.c << 'EOF'
struct A { int x; } <a: char;>;
int id_b(void) { return spec_id_of(struct A.a); }
EOF
cat > $tmp/spec3c.c << 'EOF'
struct A { int x; } <a: char;>;
int id_a(void);
int id_b(void);
int main(void) {
    int a = id_a();
    int b = id_b();
    int c = spec_id_of(struct A.a);
    if (!a || a != b || a != c)
        return 1;
    return 0;
}
EOF
$chibicc -o $tmp/spec3 $tmp/spec3a.c $tmp/spec3b.c $tmp/spec3c.c
$tmp/spec3
check 'spec id three TUs'

# Nested specialization ids
cat > $tmp/specnest.c << 'EOF'
struct A { int x; } <a: struct A; b: char;>;
int main(void) {
    int a = spec_id_of(struct A.a);
    int ab = spec_id_of(struct A.a.b);
    int b = spec_id_of(struct A.b);
    if (!a || !ab || !b)
        return 1;
    if (a == ab || ab == b || a == b)
        return 2;
    return 0;
}
EOF
$chibicc -o $tmp/specnest $tmp/specnest.c
$tmp/specnest
check 'spec_id_of nested'

# Independent generalizations keep separate counters
cat > $tmp/specgens.c << 'EOF'
struct A { int x; } <a: char;>;
struct B { int y; } <a: char;>;
int main(void) {
    int a = spec_id_of(struct A.a);
    int b = spec_id_of(struct B.a);
    if (!a || !b)
        return 1;
    return 0;
}
EOF
$chibicc -o $tmp/specgens $tmp/specgens.c
$tmp/specgens
check 'spec_id_of two generalizations'

# spec_id_of rejects a non-specialized type
echo 'int main() { return spec_id_of(int); }' | $chibicc -c -o $tmp/bad.o -xc - >/dev/null 2>&1
[ $? != 0 ]
check 'spec_id_of rejects non-spec'

echo 'struct A { int x; } <a: char;>; int main() { return spec_id_of(struct A); }' | $chibicc -c -o $tmp/bad.o -xc - >/dev/null 2>&1
[ $? != 0 ]
check 'spec_id_of rejects generalization'

# Linked binary keeps a single constructor for a shared spec
cat > $tmp/comdat1.c << 'EOF'
struct A { int x; } <a: char;>;
int id1(void) { return spec_id_of(struct A.a); }
EOF
cat > $tmp/comdat2.c << 'EOF'
struct A { int x; } <a: char;>;
int id1(void);
int main(void) { return id1() != spec_id_of(struct A.a); }
EOF
$chibicc -o $tmp/speccomdat $tmp/comdat1.c $tmp/comdat2.c
$tmp/speccomdat
n=$(nm -g $tmp/speccomdat | grep -c '__spec_reg\.A\.a')
[ "$n" = 1 ]
check 'spec ctor comdat merge'

# Variations of a parametric function defined in separate TUs share one table
cat > $tmp/pf1.c << 'EOF'
struct A { int x; } <a: int; b: char;>;
int Value<struct A.a *v>(void) { return v->@; }
EOF
cat > $tmp/pf2.c << 'EOF'
struct A { int x; } <a: int;>;
struct A + <b: char; c: long;>;
int Value<struct A.b *v>(void) { return v->@; }
int Value<struct A.a *v>(void);
int main(void) {
  struct A.a a;
  struct A.b b;
  init_spec(struct A.a, &a);
  init_spec(struct A.b, &b);
  a.@ = 5;
  b.@ = 6;
  if (Value<&a>() != 5)
    return 1;
  if (Value<&b>() != 6)
    return 2;
  return 0;
}
EOF
$chibicc -o $tmp/pfmerge $tmp/pf1.c $tmp/pf2.c
$tmp/pfmerge
check 'param func merge'

# A default defined in one TU covers specializations declared in another
cat > $tmp/pfdef1.c << 'EOF'
struct A { int x; } <a: int; b: char;>;
int Value<struct A *v>(void) { return -v->x; }
EOF
cat > $tmp/pfdef2.c << 'EOF'
struct A { int x; } <a: int; b: char;>;
int Value<struct A.a *v>(void) { return v->@; }
int main(void) {
  struct A.a a;
  struct A.b b;
  init_spec(struct A.a, &a);
  init_spec(struct A.b, &b);
  a.@ = 4;
  b.x = 9;
  if (Value<&a>() != 4)
    return 1;
  if (Value<&b>() != -9)
    return 2;
  return 0;
}
EOF
$chibicc -o $tmp/pfdefault $tmp/pfdef1.c $tmp/pfdef2.c
$tmp/pfdefault
check 'param func default across TUs'

# Identical variations in two TUs collapse into a single definition
cat > $tmp/pfcd1.c << 'EOF'
struct A { int x; } <a: int;>;
int Value<struct A.a *v>(void) { return v->@; }
int Value<struct A *v>(void) { return -v->x; }
int other(void) { return 1; }
EOF
cat > $tmp/pfcd2.c << 'EOF'
struct A { int x; } <a: int;>;
int Value<struct A.a *v>(void) { return v->@; }
int Value<struct A *v>(void) { return -v->x; }
int other(void);
int main(void) {
  struct A.a a;
  init_spec(struct A.a, &a);
  a.@ = 3;
  return Value<&a>() != 3 || other() != 1;
}
EOF
$chibicc -o $tmp/pfcomdat $tmp/pfcd1.c $tmp/pfcd2.c
$tmp/pfcomdat
check 'param func comdat merge'
for sym in '__param_func\.Value\.A\.a' '__param_func_reg\.Value' \
           '__param_func_setdef\.Value' '__param_func_tbl_init\.Value'; do
  n=$(nm $tmp/pfcomdat | grep -c "$sym")
  [ "$n" = 1 ] || { echo "testing param func single definition ... failed ($sym x$n)"; exit 1; }
done
check 'param func single definition'

echo 'struct A { int x; } <a: int;>; struct B { int y; } <p: int;>; void f<struct A.a *u, struct B.p *v>(void) {}' | $chibicc -c -o $tmp/bad.o -xc - >/dev/null 2>&1
[ $? != 0 ]
check 'param func rejects two specialized params'

echo 'struct A { int x; } <a: int;>; void f<struct A.a *v>(void) {} int main() { f(); }' | $chibicc -c -o $tmp/bad.o -xc - >/dev/null 2>&1
[ $? != 0 ]
check 'param func rejects call without specialized argument'

echo 'struct A { int x; } <a: int;>; struct B { int y; } <p: int;>; void f<struct A.a *v>(void) {} int main() { struct B.p b; f<&b>(); }' | $chibicc -c -o $tmp/bad.o -xc - >/dev/null 2>&1
[ $? != 0 ]
check 'param func rejects other generalization'

echo 'struct A { int x; } <a: int;>; void f<struct A *v>(void) {} void f<struct A *v>(void) {}' | $chibicc -c -o $tmp/bad.o -xc - >/dev/null 2>&1
[ $? != 0 ]
check 'param func rejects two defaults'

echo 'struct A { int x; } <a: int; b: int;>; void f<struct A.a *v>(int n) {} void f<struct A.b *v>(long n) {}' | $chibicc -c -o $tmp/bad.o -xc - >/dev/null 2>&1
[ $? != 0 ]
check 'param func rejects conflicting types'

echo OK
