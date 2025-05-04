// solver_diff_bugs.c
#include <stdint.h>
#include <assert.h>
#include <stdlib.h>

// Front‐end should supply nondet_* and assume() or __CPROVER_assume for CBMC/SeaHorn
extern uint32_t nondet_uint32(void);
extern int     nondet_int(void);
extern void    assume(int);

int f(int);

/* 1. Bit-vector overflow test → triggers only in a bit-level solver */
void test_overflow() {
    uint32_t x = nondet_uint32();
    uint32_t y = nondet_uint32();
    uint32_t prod = x * y;
    if (y > 1) {
        // wraparound modulo 2^32 :contentReference[oaicite:3]{index=3}
        assert(prod >= x);
    }
}

/* 2. Array‐bounds test → exercises arrays + linear integer arithmetic */
void test_array() {
    int n = nondet_int();
    assume(n > 0 && n <= 100);
    int *a = malloc(n * sizeof(int));
    int i = nondet_int();
    if (i >= 0 && i <= n) {
        a[i] = 42;     // out‐of‐bounds when i == n
        assert(i < n);
    }
}

/* 3. Uninterpreted‐functions + quantifiers → needs strong quantifier instantiation */
void test_quant() {
    int x = nondet_int();
    int y = nondet_int();
    // attempt to refute injectivity f(x)==f(y) ⇒ x==y
    if (f(x) == f(y) && x != y) {
        assert(0);
    }
}

int main() {
    test_overflow();
    test_array();
    test_quant();
    return 0;
}
