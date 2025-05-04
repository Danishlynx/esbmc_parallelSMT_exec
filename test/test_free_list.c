#include <stdlib.h>
 
struct node {
  int value;
  struct node *next;
};
 
void free_list(struct node *head) {
  for (struct node *p = head; p != NULL; p = p->next) {
    free(p);  // Bug: p is freed before p->next is accessed
  }
}

int main() {
  // Create a sample linked list
  struct node *head = (struct node *)malloc(sizeof(struct node));
  if (head == NULL) return -1;
  
  head->value = 1;
  head->next = (struct node *)malloc(sizeof(struct node));
  if (head->next == NULL) {
    free(head);
    return -1;
  }
  
  head->next->value = 2;
  head->next->next = NULL;
  
  // Call the buggy function
  free_list(head);
  
  return 0;
}
