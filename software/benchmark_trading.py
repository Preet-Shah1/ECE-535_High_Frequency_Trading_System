import csv
import random
import socket
import statistics
import sys
import time
from pathlib import Path

PORT = 5005
WARMUP = 100
SAMPLES = 1000
INTERVAL_S = 0.005
TIMEOUT_S = 2.0


def percentile(values, p):
    ordered = sorted(values)
    position = (len(ordered) - 1) * p / 100
    low = int(position)
    high = min(low + 1, len(ordered) - 1)
    fraction = position - low
    return (ordered[low] * (1 - fraction)
            + ordered[high] * fraction)


def summarize(name, values):
    print(f"\n{name}")
    print(f"  Mean:   {statistics.mean(values):.3f}")
    print(f"  Median: {statistics.median(values):.3f}")
    print(f"  P95:    {percentile(values, 95):.3f}")
    print(f"  P99:    {percentile(values, 99):.3f}")
    print(f"  Min:    {min(values):.3f}")
    print(f"  Max:    {max(values):.3f}")


def main():
    if len(sys.argv) != 3:
        print("Usage: python benchmark_trading.py "
              "<DE1SOC_IP> <arm|fpga>")
        return 1

    ip = sys.argv[1]
    mode = sys.argv[2].lower()

    if mode not in ("arm", "fpga"):
        print("Mode must be arm or fpga")
        return 1

    rng = random.Random(535)
    prices = [rng.randint(9000, 11000)
              for _ in range(WARMUP + SAMPLES)]

    # Include threshold and boundary cases.
    for index, price in enumerate(
        [9950, 10000, 10125, 9999, 10001, 0, 65535]
    ):
        prices[WARMUP + index] = price

    results = []
    failures = 0

    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.settimeout(TIMEOUT_S)
    sock.connect((ip, PORT))

    print(f"Mode: {mode.upper()}")
    print(f"Destination: {ip}:{PORT}")
    print(f"Warm-up: {WARMUP}, samples: {SAMPLES}")

    try:
        for seq, price in enumerate(prices):
            message = f"SEQ={seq},PRICE={price}"

            start = time.perf_counter_ns()
            sock.send(message.encode("ascii"))

            try:
                data = sock.recv(1024)
                end = time.perf_counter_ns()

                fields = dict(
                    part.split("=", 1)
                    for part in data.decode("ascii").split(",")
                )

                if int(fields.get("SEQ", -1)) != seq:
                    raise ValueError("Sequence mismatch")

                if "ERROR" in fields:
                    raise ValueError(fields["ERROR"])

                decision = fields["DECISION"]
                proc_ns = int(fields["PROC_NS"])

                expected = (
                    "BUY" if price < 10000
                    else "SELL" if price > 10000
                    else "HOLD"
                )

                correct = decision == expected
                if not correct:
                    failures += 1

                if seq >= WARMUP:
                    results.append({
                        "mode": mode,
                        "seq": seq,
                        "price": price,
                        "decision": decision,
                        "expected": expected,
                        "correct": correct,
                        "proc_ns": proc_ns,
                        "rtt_us": (end - start) / 1000.0,
                    })

            except (socket.timeout, ValueError,
                    KeyError, UnicodeError) as exc:
                print(f"Packet {seq} failed: {exc}")
                failures += 1
                # Abort to avoid attributing a delayed
                # UDP response to a later request.
                break

            if (seq + 1) % 100 == 0:
                print(f"Completed {seq + 1}/{len(prices)}")

            time.sleep(INTERVAL_S)

    finally:
        sock.close()

    if not results:
        print("No measured results")
        return 1

    output = Path(__file__).with_name(
        f"benchmark_{mode}.csv"
    )

    with output.open("w", newline="") as file:
        writer = csv.DictWriter(
            file, fieldnames=results[0].keys()
        )
        writer.writeheader()
        writer.writerows(results)

    rtt = [r["rtt_us"] for r in results]
    processing = [r["proc_ns"] / 1000.0
                  for r in results]

    print("\n========== BENCHMARK ==========")
    print(f"Mode: {mode.upper()}")
    print(f"Measured responses: {len(results)}/{SAMPLES}")
    print(f"Total observed failures: {failures}")
    print(f"Correct measured decisions: "
          f"{sum(r['correct'] for r in results)}"
          f"/{len(results)}")

    summarize("Network RTT (microseconds)", rtt)
    summarize("Processing path (microseconds)",
              processing)

    print(f"\nCSV saved to: {output}")

    return 0 if failures == 0 and len(results) == SAMPLES else 1


if __name__ == "__main__":
    sys.exit(main())