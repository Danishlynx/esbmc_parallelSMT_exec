#include <stdlib.h>
 
enum { BUFFER_SIZE = 32 };
 
int f(void) {
  char *text_buffer = (char *)malloc(BUFFER_SIZE);
  if (text_buffer == NULL) {
    return -1;
  }
  return 0;  // Bug: No free(text_buffer) before returning
}

int main() {
  return f();
}
