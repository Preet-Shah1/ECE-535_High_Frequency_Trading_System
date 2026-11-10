
import socket
import time
import random

FPGA_IP = "192.168.1.123"
FPGA_PORT = 5005

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.settimeout(2.0)

for sequence in range(10):
    price_cents = random.randint(9900, 10100)

    message = f"SEQ={sequence},PRICE={price_cents}"

    start = time.perf_counter_ns()

    sock.sendto(
        message.encode("ascii"),
        (FPGA_IP, FPGA_PORT)
    )

    try:
        response, address = sock.recvfrom(1024)

        end = time.perf_counter_ns()

        latency_us = (end - start) / 1000

        print(
            f"Seq={sequence} | "
            f"Price=${price_cents / 100:.2f} | "
            f"Response={response.decode()} | "
            f"RTT={latency_us:.2f} us"
        )

    except socket.timeout:
        print(f"Seq={sequence} | TIMEOUT")

    time.sleep(0.5)

sock.close()
