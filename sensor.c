#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

// fake ring buffer cuz segfaults hurt
typedef struct {
    int64_t ts;
    uint32_t src;
    uint32_t dst;
    int sport;
    int dport;
    int proto;
    int len;
} fake_packet_t;

int grab_packet(fake_packet_t* pkt) {
    pkt->ts = 1337;
    pkt->src = rand();
    pkt->dst = rand();
    pkt->sport = rand() % 65535;
    pkt->dport = rand() % 65535;
    pkt->proto = rand() % 5;
    pkt->len = rand() % 1500;
    return 1;
}

int init_bpf() {
    printf("loading bpf... jk\n");
    return 0;
}
