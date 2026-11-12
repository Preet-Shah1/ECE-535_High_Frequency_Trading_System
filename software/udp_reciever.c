#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <sys/socket.h>

#define PORT 5005
#define BUFFER_SIZE 1024

int main(void) {
    int sockfd;
    struct sockaddr_in server_addr, client_addr;
    socklen_t client_len;
    char buffer[BUFFER_SIZE];

    sockfd = socket(AF_INET, SOCK_DGRAM, 0);

    if (sockfd < 0) {
        perror("socket");
        return 1;
    }

    memset(&server_addr, 0, sizeof(server_addr));

    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(PORT);
    server_addr.sin_addr.s_addr = htonl(INADDR_ANY);

    if (bind(sockfd,
             (struct sockaddr *)&server_addr,
             sizeof(server_addr)) < 0) {
        perror("bind");
        close(sockfd);
        return 1;
    }

    printf("UDP receiver listening on port %d...\n", PORT);
    fflush(stdout);

    while (1) {
        client_len = sizeof(client_addr);

        ssize_t bytes_received = recvfrom(
            sockfd,
            buffer,
            BUFFER_SIZE - 1,
            0,
            (struct sockaddr *)&client_addr,
            &client_len
        );

        if (bytes_received < 0) {
            perror("recvfrom");
            continue;
        }

        buffer[bytes_received] = '\0';

        printf("Received: %s\n", buffer);
        fflush(stdout);

        const char *response = "ACK";

        if (sendto(
                sockfd,
                response,
                strlen(response),
                0,
                (struct sockaddr *)&client_addr,
                client_len
            ) < 0) {
            perror("sendto");
        }
    }

    close(sockfd);
    return 0;
}
root@de1soclinux:~/535#
