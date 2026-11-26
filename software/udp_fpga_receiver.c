#define _POSIX_C_SOURCE 200809L

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <errno.h>
#include <fcntl.h>
#include <unistd.h>
#include <time.h>
#include <arpa/inet.h>
#include <sys/socket.h>
#include <sys/mman.h>

#define PORT 5005
#define FPGA_BASE 0xFF200000UL
#define MAP_SIZE 4096

#define PRICE_REG    0x00
#define CONTROL_REG  0x10
#define DECISION_REG 0x20
#define STATUS_REG   0x30

#define TIMEOUT_NS 1000000000LL

static volatile uint32_t *regs;

static uint32_t read_reg(unsigned offset)
{
    uint32_t value = regs[offset / 4];
    __sync_synchronize();
    return value;
}

static void write_reg(unsigned offset, uint32_t value)
{
    __sync_synchronize();
    regs[offset / 4] = value;
    __sync_synchronize();
}

static long long now_ns(void)
{
    struct timespec ts;

    if (clock_gettime(CLOCK_MONOTONIC, &ts) != 0) {
        perror("clock_gettime");
        exit(1);
    }

    return (long long)ts.tv_sec * 1000000000LL
         + ts.tv_nsec;
}

/*
 * Returns:
 *  0 = success
 * -1 = previous request not completed
 * -2 = timeout
 *
 * Single-threaded: only one transaction at a time.
 */
static int process_fpga(uint16_t price,
                        uint32_t *decision,
                        double *latency_us)
{
    unsigned control = read_reg(CONTROL_REG) & 1u;
    unsigned status  = read_reg(STATUS_REG) & 1u;

    if (control != status)
        return -1;

    unsigned request = control ^ 1u;

    long long start = now_ns();

    write_reg(PRICE_REG, price);
    write_reg(CONTROL_REG, request);

    while ((read_reg(STATUS_REG) & 1u) != request) {
        if (now_ns() - start > TIMEOUT_NS)
            return -2;
    }

    *decision = read_reg(DECISION_REG) & 3u;

    long long end = now_ns();
    *latency_us = (end - start) / 1000.0;

    return 0;
}

static const char *decision_name(uint32_t decision)
{
    switch (decision) {
        case 0: return "HOLD";
        case 1: return "BUY";
        case 2: return "SELL";
        default: return "INVALID";
    }
}

int main(void)
{
    int memfd = open("/dev/mem", O_RDWR | O_SYNC);

    if (memfd < 0) {
        perror("open /dev/mem");
        return 1;
    }

    void *map = mmap(NULL, MAP_SIZE,
                     PROT_READ | PROT_WRITE,
                     MAP_SHARED, memfd, FPGA_BASE);

    if (map == MAP_FAILED) {
        perror("mmap");
        close(memfd);
        return 1;
    }

    regs = (volatile uint32_t *)map;

    printf("FPGA control=%u status=%u\n",
           read_reg(CONTROL_REG) & 1u,
           read_reg(STATUS_REG) & 1u);

    int sockfd = socket(AF_INET, SOCK_DGRAM, 0);
    if (sockfd < 0) {
        perror("socket");
        munmap(map, MAP_SIZE);
        close(memfd);
        return 1;
    }

    struct sockaddr_in server;
    memset(&server, 0, sizeof(server));
    server.sin_family = AF_INET;
    server.sin_port = htons(PORT);
    server.sin_addr.s_addr = htonl(INADDR_ANY);

    if (bind(sockfd, (struct sockaddr *)&server,
             sizeof(server)) < 0) {
        perror("bind");
        close(sockfd);
        munmap(map, MAP_SIZE);
        close(memfd);
        return 1;
    }

    printf("UDP FPGA receiver listening on port %d\n", PORT);
    fflush(stdout);

    while (1) {
        char buffer[256];
        char response[256];
        struct sockaddr_in client;
        memset(&client, 0, sizeof(client));
        socklen_t client_len = sizeof(client);

        ssize_t n = recvfrom(
            sockfd, buffer, sizeof(buffer) - 1, 0,
            (struct sockaddr *)&client, &client_len
        );

        if (n < 0) {
            if (errno == EINTR)
                continue;
            perror("recvfrom");
            break;
        }

        buffer[n] = '\0';

        unsigned seq, price;
        char extra;

        // Accept exactly SEQ=<uint>,PRICE=<uint>
        if (sscanf(buffer, "SEQ=%u,PRICE=%u%c",
                   &seq, &price, &extra) != 2 ||
            price > 65535u) {

            snprintf(response, sizeof(response),
                     "ERROR=BAD_PACKET");
        } else {
            uint32_t decision = 0;
            double latency_us = 0.0;

            int rc = process_fpga((uint16_t)price,
                                  &decision, &latency_us);

            if (rc != 0) {
                snprintf(response, sizeof(response),
                         "SEQ=%u,ERROR=FPGA_%s",
                         seq, rc == -2 ? "TIMEOUT" : "STATE");

                fprintf(stderr,
                        "FPGA transaction failed (%d). "
                        "Stopping receiver.\n", rc);

                sendto(sockfd, response, strlen(response), 0,
                       (struct sockaddr *)&client, client_len);
                break;
            }

            snprintf(response, sizeof(response),
                     "SEQ=%u,DECISION=%s,FPGA_US=%.2f",
                     seq, decision_name(decision), latency_us);

            printf("SEQ=%u PRICE=%u DECISION=%s "
                   "HPS_FPGA_US=%.2f\n",
                   seq, price, decision_name(decision),
                   latency_us);
            fflush(stdout);
        }

        if (sendto(sockfd, response, strlen(response), 0,
                   (struct sockaddr *)&client,
                   client_len) < 0) {
            perror("sendto");
        }
    }

    close(sockfd);
    munmap(map, MAP_SIZE);
    close(memfd);
    return 0;
}
