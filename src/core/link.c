#include <stdint.h>
#include <stdbool.h>
#include "link.h"
#include "packet.h"

int size = 8192;

struct packet *link_receive(struct link *r) {
  struct packet *p;

  p = r->packets[r->read];
  r->read = (r->read + 1) % size;
  r->stats.rxpackets = r->stats.rxpackets + 1;
  r->stats.rxbytes = r->stats.rxbytes + p->length;
  return(p);
}

void link_transmit(struct link *r, struct packet *p) {
  if ((r->write + 1) % 8192 == r->read) {
    r->stats.txdrop = r->stats.txdrop + 1;
  } else {
    r->packets[r->write] = p;
    r->write = (r->write + 1) % size;
    r->stats.txpackets = r->stats.txpackets + 1;
    r->stats.txbytes   = r->stats.txbytes + p->length;
    r->has_new_data = true;
  }
}
