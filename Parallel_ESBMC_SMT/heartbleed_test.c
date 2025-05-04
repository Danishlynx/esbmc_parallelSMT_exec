#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

/* mimic OpenSSL’s n2s macro */
#define n2s(p, s) \
  do { \
    (s) = ((unsigned short)(p[0]) << 8) | (unsigned short)(p[1]); \
    p += 2; \
  } while (0)

/* Vulnerable “heartbeat” parser */
void tls_heartbeat(unsigned char *input, size_t len) {
    unsigned char *p = input;
    unsigned short hbtype;
    unsigned int payload;
    unsigned int padding = 16;
    unsigned char pad[16] = {0};

    /* parse message header */
    hbtype = *p++;
    n2s(p, payload);

    /* --- HERE: no check that payload <= (len - 3) --- */
    printf("Declared payload length = %u, actual data = %zu bytes\n",
           payload, len - 3);

    unsigned char *buf = malloc(payload + padding);
    if (!buf) return;

    /* this memcpy may read past the end of input */
    memcpy(buf, p, payload);
    memcpy(buf + payload, pad, padding);
    free(buf);
}

int main(void) {
    /* craft a 3-byte record claiming 16 384-byte payload */
    unsigned char hb[] = {
        0x01,        /* heartbeat request */
        0x40, 0x00   /* payload length = 0x4000 (16384) */
        /* …no actual payload bytes follow… */
    };
    tls_heartbeat(hb, sizeof(hb));
    return 0;
}
