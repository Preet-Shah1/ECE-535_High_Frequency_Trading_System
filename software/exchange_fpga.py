
import socket
import time
import csv
from pathlib import Path

FPGA_IP = "192.168.1.123"
FPGA_PORT = 5005

# Price values in cents
PRICES = [9950, 10000, 10125, 9800, 10200,
          9999, 10001, 9750, 10000, 10500]

results = []

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.settimeout(2.0)

try:
    for seq, price in enumerate(PRICES):
        message = f"SEQ={seq},PRICE={price}"

        start_ns = time.perf_counter_ns()
        sock.sendto(
            message.encode("ascii"),
            (FPGA_IP, FPGA_PORT)
        )

        try:
            data, address = sock.recvfrom(1024)
            end_ns = time.perf_counter_ns()

            response = data.decode("ascii")
            fields = dict(
                part.split("=", 1)
                for part in response.split(",")
            )

            if address != (FPGA_IP, FPGA_PORT):
                print(f"SEQ={seq}: unexpected sender {address}")
                continue

            if int(fields.get("SEQ", -1)) != seq:
                print(f"SEQ={seq}: mismatched response {response}")
                continue

            if "ERROR" in fields:
                print(f"SEQ={seq}: FPGA error {fields['ERROR']}")
                break

            decision = fields["DECISION"]
            fpga_us = float(fields["FPGA_US"])
            rtt_us = (end_ns - start_ns) / 1000.0

            expected = (
                "BUY" if price < 10000
                else "SELL" if price > 10000
                else "HOLD"
            )

            passed = decision == expected

            print(
                f"SEQ={seq:02d} | "
                f"PRICE=${price / 100:.2f} | "
                f"DECISION={decision:4s} | "
                f"HPS-FPGA={fpga_us:.2f} us | "
                f"RTT={rtt_us:.2f} us | "
                f"{'PASS' if passed else 'FAIL'}"
            )

            results.append({
                "sequence": seq,
                "price_cents": price,
                "expected": expected,
                "decision": decision,
                "passed": passed,
                "hps_fpga_us": fpga_us,
                "rtt_us": rtt_us,
            })

        except socket.timeout:
            print(f"SEQ={seq}: TIMEOUT")
            break
        except (ValueError, KeyError, UnicodeError) as exc:
            print(f"SEQ={seq}: invalid response: {exc}")
            break

        time.sleep(0.2)

finally:
    sock.close()

if results:
    output = Path(__file__).with_name("fpga_results.csv")

    with output.open("w", newline="") as file:
        writer = csv.DictWriter(
            file, fieldnames=results[0].keys()
        )
        writer.writeheader()
        writer.writerows(results)

    avg_fpga = sum(r["hps_fpga_us"] for r in results) / len(results)
    avg_rtt = sum(r["rtt_us"] for r in results) / len(results)
    passed = sum(r["passed"] for r in results)

    print("\n--- RESULTS ---")
    print(f"Valid responses: {len(results)}/{len(PRICES)}")
    print(f"Correct decisions: {passed}/{len(results)}")
    print(f"Average HPS-FPGA transaction: {avg_fpga:.2f} us")
    print(f"Average network RTT: {avg_rtt:.2f} us")
    print(f"Saved results: {output}")
