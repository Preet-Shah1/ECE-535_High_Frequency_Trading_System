# ECE-535_High_Frequency_Trading_System
Developing a system to lower the time it takes to complete a trade by optimizing the handling and delivery of packets to/from a "trading firm". 

## Motivation

The goal of this project is to learn about optimizing hardware and software for low-latency networked embedded systems using an FPGA-based trading platform.

A PC-based exchange simulator will send market data over Ethernet to an FPGA. The FPGA will process incoming packets, maintain a simplified market state, execute a trading algorithm, and return order messages.

The main goal is to compare FPGA-based processing against a conventional software implementation in terms of latency, jitter, throughput, and determinism.

We wanted to explore projects with FPGAs, as that is an area of interest, and networking with FPGAs is a research area that is continuously growing, and learning about it is exciting!

## Design Goals

- Receive and transmit market data over Ethernet.
- Parse network and market-data packets on the FPGA.
- Maintain a simplified order book.
- Execute a basic trading algorithm in hardware.
- Generate outgoing order messages.
- Measure end-to-end processing latency.
- Compare FPGA performance with a software implementation and potentially verify with real hardware.

## System Blocks

```text
+-------------------+
| Exchange Simulator|
|      PC           |
+---------+---------+
          |
       Ethernet
          |
          v
+--------------------------+
| FPGA Trading System      |
|                          |
| Ethernet RX              |
|      |                   |
| Packet Parser            |
|      |                   |
| Order Book               |
|      |                   |
| Trading Algorithm        |
|      |                   |
| Risk Checks              |
|      |                   |
| Order Generator          |
|      |                   |
| Ethernet TX              |
+--------------------------+
```

## Hardware Requirements

- FPGA development board
- Ethernet interface/PHY
- Development computer/server
- Ethernet connection
- FPGA programming/debug interface

## Software Requirements

- Verilog/SystemVerilog
- FPGA development tools such as Vivado
- C++ or Python for the exchange simulator
- C++ for the software baseline
- Git/GitHub
- Wireshark and HDL simulation tools for testing (Icarus Verilog)

## Deliverables

- FPGA Ethernet communication
- Market-data packet parser
- Simplified FPGA order book
- FPGA trading algorithm
- Basic hardware risk checks
- FPGA order packet generator
- PC-based exchange simulator
- Equivalent software implementation
- FPGA versus software latency comparison
- Final system demonstration and documentation

## Team Responsibilities

### Preet - Setup and Networking Lead
- FPGA development environment
- Ethernet interface and network protocol
- FPGA system integration
- Timing and latency measurement

### Manav - Software and Algorithm Design Lead
- Exchange simulator
- Software baseline
- Trading algorithm design
- Test and benchmark software

### Rohit - Research and Writing Lead
- Background research
- FPGA/networking technology research
- Documentation
- Results organization
- Final report and presentation

All team members will contribute to debugging, integration, testing, and the final demonstration.

## Project Timeline

| Weeks | Goals |
|---|---|
| 1–2 | Finalize architecture, FPGA setup, define communication protocol |
| 3–4 | Implement Ethernet communication |
| 5–6 | Implement market-data parser and exchange simulator |
| 7–8 | Implement order book and trading algorithm |
| 9–10 | Implement order generation and risk checks |
| 11–12 | Build software baseline and perform latency testing |
| 13–14 | Final integration, documentation, and presentation |

## References

- IEEE 802.3 Ethernet Standard
- AMD/Xilinx FPGA and Ethernet documentation
- Open-source FPGA Ethernet/UDP implementations
- Academic research on FPGA-based low-latency networking and trading systems
