#include <stdlib.h>
#include <string.h>
#include <stdio.h>
 
enum { MAX_ALLOCATION = 1000 };
 
int main(int argc, const char *argv[]) {
  char *c_str = NULL;
  size_t len;
 
  if (argc == 2) {
    len = strlen(argv[1]) + 1;
    if (len > MAX_ALLOCATION) {
      /* Handle error */
      return -1;
    }
    c_str = (char *)malloc(len);
    if (c_str == NULL) {
      /* Handle error */
      return -1;
    }
    strcpy(c_str, argv[1]);
  } else {
    c_str = "usage: $>a.exe [string]";  // Bug: c_str points to string literal
    printf("%s\n", c_str);
  }
  free(c_str);  // Bug: Attempts to free string literal if argc != 2
  return 0;
}
